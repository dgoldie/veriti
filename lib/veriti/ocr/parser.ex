defmodule Veriti.OCR.Parser do
  @moduledoc """
  Extracts structured fields from raw OCR text of a vehicle title document.
  All extraction is best-effort; fields may be nil when not detected.
  """

  # VIN: 17 chars, no I/O/Q
  @vin_regex ~r/\b([A-HJ-NPR-Z0-9]{17})\b/

  # Title number: labeled variants common on state titles
  @title_number_regex ~r/(?:title\s*(?:number|no\.?|num\.?|#)\s*[:\-]?\s*)([A-Z0-9]{5,15})/i

  # Odometer: number after keyword
  @odometer_regex ~r/(?:odometer|mileage|miles)\s*[:\-]?\s*([\d,]+)/i

  # Owner name: line after labeled field
  @owner_regex ~r/(?:registered\s+owner|owner\s+name|owner)[:\s]+([A-Z][A-Z ,.\-']{2,60})/i

  # Lienholder: name after lien field label
  @lienholder_regex ~r/(?:first\s+lienholder?|lienholder?|lien\s+holder)[:\s]+([A-Z][A-Z ,.\-'&]{2,80})/i

  @state_names %{
    "ALABAMA" => "AL", "ALASKA" => "AK", "ARIZONA" => "AZ", "ARKANSAS" => "AR",
    "CALIFORNIA" => "CA", "COLORADO" => "CO", "CONNECTICUT" => "CT", "DELAWARE" => "DE",
    "FLORIDA" => "FL", "GEORGIA" => "GA", "HAWAII" => "HI", "IDAHO" => "ID",
    "ILLINOIS" => "IL", "INDIANA" => "IN", "IOWA" => "IA", "KANSAS" => "KS",
    "KENTUCKY" => "KY", "LOUISIANA" => "LA", "MAINE" => "ME", "MARYLAND" => "MD",
    "MASSACHUSETTS" => "MA", "MICHIGAN" => "MI", "MINNESOTA" => "MN", "MISSISSIPPI" => "MS",
    "MISSOURI" => "MO", "MONTANA" => "MT", "NEBRASKA" => "NE", "NEVADA" => "NV",
    "NEW HAMPSHIRE" => "NH", "NEW JERSEY" => "NJ", "NEW MEXICO" => "NM", "NEW YORK" => "NY",
    "NORTH CAROLINA" => "NC", "NORTH DAKOTA" => "ND", "OHIO" => "OH", "OKLAHOMA" => "OK",
    "OREGON" => "OR", "PENNSYLVANIA" => "PA", "RHODE ISLAND" => "RI", "SOUTH CAROLINA" => "SC",
    "SOUTH DAKOTA" => "SD", "TENNESSEE" => "TN", "TEXAS" => "TX", "UTAH" => "UT",
    "VERMONT" => "VT", "VIRGINIA" => "VA", "WASHINGTON" => "WA", "WEST VIRGINIA" => "WV",
    "WISCONSIN" => "WI", "WYOMING" => "WY"
  }

  @valid_state_abbrevs Map.values(@state_names)

  def parse(raw_text) do
    upper = String.upcase(raw_text)
    %{
      vin: extract_vin(raw_text),
      title_number: extract_field(raw_text, @title_number_regex),
      owner: extract_field(raw_text, @owner_regex),
      odometer: extract_odometer(raw_text),
      lienholder: extract_field(raw_text, @lienholder_regex),
      state: extract_state(upper)
    }
  end

  defp extract_vin(text) do
    case Regex.run(@vin_regex, String.upcase(text)) do
      [_, vin] -> vin
      _ -> nil
    end
  end

  defp extract_field(text, regex) do
    case Regex.run(regex, text) do
      [_, value] -> String.trim(value)
      _ -> nil
    end
  end

  defp extract_odometer(text) do
    case Regex.run(@odometer_regex, text, capture: :all_but_first) do
      [miles] -> String.replace(miles, ",", "")
      _ -> nil
    end
  end

  defp extract_state(upper_text) do
    abbrev = extract_state_from_label(upper_text)
    abbrev || extract_state_abbreviation(upper_text)
  end

  defp extract_state_from_label(upper_text) do
    case Regex.run(~r/STATE\s+OF\s+([A-Z\s]+?)(?:\n|CERTIFICATE|TITLE|$)/, upper_text) do
      [_, name] ->
        name = String.trim(name)
        Map.get(@state_names, name) || find_partial_match(name)
      _ ->
        nil
    end
  end

  defp find_partial_match(name) do
    Enum.find_value(@state_names, fn {full, abbrev} ->
      if String.contains?(name, full), do: abbrev
    end)
  end

  defp extract_state_abbreviation(upper_text) do
    case Regex.run(~r/\b([A-Z]{2})\s+(?:TITLE|CERTIFICATE|MOTOR VEHICLE)/, upper_text) do
      [_, code] -> if code in @valid_state_abbrevs, do: code
      _ -> nil
    end
  end
end
