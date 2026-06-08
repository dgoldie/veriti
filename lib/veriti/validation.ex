defmodule Veriti.Validation do
  @moduledoc """
  Orchestrates OCR extraction and validation for a title submission.
  Also contains pure validation logic for VIN, title numbers, and lien detection.
  """

  require Logger

  alias Veriti.{OCR, Repo, TitleSubmissions}
  alias Veriti.OCR.Parser
  alias Veriti.Validation.Result

  # VIN check-digit weights (ISO 3779), indexed by position 0–16
  @vin_weights [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2]

  @vin_char_values %{
    "A" => 1, "B" => 2, "C" => 3, "D" => 4, "E" => 5, "F" => 6, "G" => 7, "H" => 8,
    "J" => 1, "K" => 2, "L" => 3, "M" => 4, "N" => 5,
    "P" => 7, "R" => 9,
    "S" => 2, "T" => 3, "U" => 4, "V" => 5, "W" => 6, "X" => 7, "Y" => 8, "Z" => 9,
    "0" => 0, "1" => 1, "2" => 2, "3" => 3, "4" => 4,
    "5" => 5, "6" => 6, "7" => 7, "8" => 8, "9" => 9
  }

  # State-specific title number format patterns
  @state_title_patterns %{
    "CA" => ~r/^\d{8}$/,
    "TX" => ~r/^[A-Z0-9]{8,12}$/,
    "FL" => ~r/^\d{9,10}[A-Z]?$/,
    "NY" => ~r/^[A-Z0-9]{8,10}$/,
    "OH" => ~r/^[A-Z0-9]{8}$/,
    "MI" => ~r/^\d{9}$/,
    "IL" => ~r/^\d{7}$/,
    "PA" => ~r/^\d{8}$/,
    "GA" => ~r/^[A-Z0-9]{7,10}$/,
    "NC" => ~r/^\d{9,10}$/,
    "WA" => ~r/^[A-Z0-9]{8,11}$/,
    "AZ" => ~r/^\d{8,9}$/,
    "CO" => ~r/^[A-Z0-9]{6,10}$/,
    "MN" => ~r/^\d{8,10}$/,
    "MO" => ~r/^[A-Z0-9]{8,12}$/,
    "WI" => ~r/^[A-Z0-9]{8,10}$/
  }

  @lien_keywords ["lien", "lienholder", "lienholders", "first lien", "second lien",
                  "first lienholder", "second lienholder"]

  # ---------------------------------------------------------------------------
  # Orchestration
  # ---------------------------------------------------------------------------

  @doc """
  Runs the full OCR + validation pipeline for a submission.
  Updates the submission status and persists a ValidationResult record.
  Designed to be called from a background task.
  """
  def process(%{id: submission_id, file_path: file_path, content_type: content_type} = submission) do
    TitleSubmissions.update_submission_status(submission, "processing")

    case OCR.extract_text(file_path, content_type) do
      {:ok, raw_text} ->
        fields = Parser.parse(raw_text)
        {statuses, issues} = run_checks(fields, raw_text)
        overall = compute_overall(statuses)

        result_attrs =
          Map.merge(fields_to_attrs(fields), %{
            raw_text: raw_text,
            vin_status: to_string(statuses.vin),
            title_number_status: to_string(statuses.title_number),
            lien_status: to_string(statuses.lien),
            overall_status: overall,
            issues: issues,
            submission_id: submission_id
          })

        %Result{}
        |> Result.changeset(result_attrs)
        |> Repo.insert!()

        TitleSubmissions.update_submission_status(submission, "completed")

      {:error, :pdf_not_supported} ->
        persist_error(submission_id, "PDF OCR is not yet supported. Please upload a JPG or PNG image.")
        TitleSubmissions.update_submission_status(submission, "failed")

      {:error, reason} ->
        Logger.warning("OCR failed for submission #{submission_id}: #{inspect(reason)}")
        persist_error(submission_id, "OCR processing failed: #{reason}")
        TitleSubmissions.update_submission_status(submission, "failed")
    end
  end

  # ---------------------------------------------------------------------------
  # Pure validation functions (public for testing)
  # ---------------------------------------------------------------------------

  @doc "Returns {:pass | :fail | :not_found, message | nil} for a VIN string."
  def validate_vin(nil), do: {:not_found, "VIN not detected in document"}

  def validate_vin(vin) when byte_size(vin) == 17 do
    if valid_vin_checksum?(vin),
      do: {:pass, nil},
      else: {:fail, "VIN check digit is invalid (ISO 3779)"}
  end

  def validate_vin(_), do: {:fail, "VIN is not 17 characters"}

  @doc "Returns {:pass | :fail | :warning | :not_found, message | nil} for a title number."
  def validate_title_number(nil, _state), do: {:not_found, "Title number not detected"}

  def validate_title_number(number, state) do
    case Map.get(@state_title_patterns, state) do
      nil ->
        {:warning, "No state-specific rules available#{if state, do: " for #{state}", else: ""}"}

      pattern ->
        if Regex.match?(pattern, number),
          do: {:pass, nil},
          else: {:fail, "Title number format does not match #{state} requirements"}
    end
  end

  @doc "Returns :detected | :none based on presence of lien keywords in raw text."
  def detect_lien(raw_text) when is_binary(raw_text) do
    lower = String.downcase(raw_text)
    if Enum.any?(@lien_keywords, &String.contains?(lower, &1)), do: :detected, else: :none
  end

  def detect_lien(_), do: :none

  @doc "Returns true if the 17-character VIN has a valid ISO 3779 check digit."
  def valid_vin_checksum?(vin) when byte_size(vin) == 17 do
    chars = String.graphemes(String.upcase(vin))
    values = Enum.map(chars, &Map.get(@vin_char_values, &1, -1))

    if Enum.any?(values, &(&1 == -1)) do
      false
    else
      sum =
        values
        |> Enum.zip(@vin_weights)
        |> Enum.map(fn {v, w} -> v * w end)
        |> Enum.sum()

      remainder = rem(sum, 11)
      expected = if remainder == 10, do: "X", else: Integer.to_string(remainder)
      Enum.at(chars, 8) == expected
    end
  end

  def valid_vin_checksum?(_), do: false

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp run_checks(fields, raw_text) do
    vin_result = validate_vin(fields.vin)
    title_result = validate_title_number(fields.title_number, fields.state)
    lien_result = detect_lien(raw_text)

    statuses = %{
      vin: elem(vin_result, 0),
      title_number: elem(title_result, 0),
      lien: lien_result
    }

    issues =
      [vin_result, title_result]
      |> Enum.map(&elem(&1, 1))
      |> Enum.reject(&is_nil/1)
      |> then(fn msgs ->
        if lien_result == :detected, do: ["Lienholder detected on title" | msgs], else: msgs
      end)

    {statuses, issues}
  end

  defp compute_overall(%{vin: vin_s, title_number: tn_s}) do
    cond do
      vin_s == :fail or tn_s == :fail -> "fail"
      vin_s in [:not_found, :warning] or tn_s in [:not_found, :warning] -> "warning"
      true -> "pass"
    end
  end

  defp fields_to_attrs(fields) do
    %{
      extracted_vin: fields.vin,
      extracted_title_number: fields.title_number,
      extracted_owner: fields.owner,
      extracted_odometer: fields.odometer,
      extracted_lienholder: fields.lienholder,
      extracted_state: fields.state
    }
  end

  defp persist_error(submission_id, message) do
    %Result{}
    |> Result.changeset(%{
      overall_status: "fail",
      issues: [message],
      submission_id: submission_id
    })
    |> Repo.insert()
  end
end
