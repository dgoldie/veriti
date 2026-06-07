defmodule Veriti.Repo.Migrations.CreateTitleSubmissions do
  use Ecto.Migration

  def change do
    create table(:title_submissions) do
      add :file_path, :string, null: false
      add :original_filename, :string, null: false
      add :content_type, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:title_submissions, [:user_id])
  end
end
