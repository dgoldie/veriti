defmodule Veriti.TitleSubmissions do
  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query

  alias Veriti.Repo
  alias Veriti.TitleSubmissions.TitleSubmission

  def list_user_submissions(user_id) do
    TitleSubmission
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_submission!(id), do: Repo.get!(TitleSubmission, id)

  def create_submission(attrs) do
    %TitleSubmission{}
    |> TitleSubmission.changeset(attrs)
    |> Repo.insert()
  end

  def update_submission_status(%TitleSubmission{} = submission, status) do
    submission
    |> change(status: status)
    |> Repo.update()
  end
end
