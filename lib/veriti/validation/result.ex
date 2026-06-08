defmodule Veriti.Validation.Result do
  use Ecto.Schema
  import Ecto.Changeset

  schema "validation_results" do
    field :raw_text, :string
    field :extracted_vin, :string
    field :extracted_title_number, :string
    field :extracted_owner, :string
    field :extracted_odometer, :string
    field :extracted_lienholder, :string
    field :extracted_state, :string
    field :vin_status, :string
    field :title_number_status, :string
    field :lien_status, :string
    field :overall_status, :string
    field :issues, {:array, :string}, default: []

    belongs_to :submission, Veriti.TitleSubmissions.TitleSubmission

    timestamps(type: :utc_datetime)
  end

  @statuses ~w(pass fail warning not_found)
  @lien_statuses ~w(none detected)
  @overall_statuses ~w(pass fail warning)

  def changeset(result, attrs) do
    result
    |> cast(attrs, [
      :raw_text,
      :extracted_vin,
      :extracted_title_number,
      :extracted_owner,
      :extracted_odometer,
      :extracted_lienholder,
      :extracted_state,
      :vin_status,
      :title_number_status,
      :lien_status,
      :overall_status,
      :issues,
      :submission_id
    ])
    |> validate_required([:overall_status, :submission_id])
    |> validate_inclusion(:vin_status, @statuses, allow_nil: true)
    |> validate_inclusion(:title_number_status, @statuses, allow_nil: true)
    |> validate_inclusion(:lien_status, @lien_statuses, allow_nil: true)
    |> validate_inclusion(:overall_status, @overall_statuses)
    |> foreign_key_constraint(:submission_id)
    |> unique_constraint(:submission_id)
  end
end
