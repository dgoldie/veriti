defmodule Veriti.Repo.Migrations.CreateValidationResults do
  use Ecto.Migration

  def change do
    create table(:validation_results) do
      add :submission_id, references(:title_submissions, on_delete: :delete_all), null: false
      add :raw_text, :text
      add :extracted_vin, :string, size: 17
      add :extracted_title_number, :string, size: 50
      add :extracted_owner, :string, size: 200
      add :extracted_odometer, :string, size: 20
      add :extracted_lienholder, :string, size: 200
      add :extracted_state, :string, size: 2
      add :vin_status, :string, size: 10
      add :title_number_status, :string, size: 10
      add :lien_status, :string, size: 10
      add :overall_status, :string, size: 10
      add :issues, {:array, :string}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:validation_results, [:submission_id])
    create index(:validation_results, [:overall_status])
  end
end
