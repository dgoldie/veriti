defmodule Veriti.TitleSubmissions do
  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query

  alias Veriti.Repo
  alias Veriti.TitleSubmissions.TitleSubmission

  @per_page 20

  def list_user_submissions(user_id, page \\ 1) do
    offset = (page - 1) * @per_page

    TitleSubmission
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> limit(@per_page)
    |> offset(^offset)
    |> Repo.all()
  end

  def count_user_submissions(user_id) do
    TitleSubmission
    |> where(user_id: ^user_id)
    |> Repo.aggregate(:count)
  end

  def get_submission!(id), do: Repo.get!(TitleSubmission, id)

  def get_user_submission!(user_id, id) do
    TitleSubmission
    |> where(id: ^id, user_id: ^user_id)
    |> Repo.one!()
  end

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
