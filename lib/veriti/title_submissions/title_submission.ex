defmodule Veriti.TitleSubmissions.TitleSubmission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "title_submissions" do
    field :file_path, :string
    field :original_filename, :string
    field :content_type, :string
    field :status, :string, default: "pending"

    belongs_to :user, Veriti.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @statuses ~w(pending processing completed failed)

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [:file_path, :original_filename, :content_type, :status, :user_id])
    |> validate_required([:file_path, :original_filename, :content_type, :user_id])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:user_id)
  end
end
