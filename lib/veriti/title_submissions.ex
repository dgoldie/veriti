defmodule Veriti.TitleSubmissions do
  import Ecto.Query

  alias Veriti.Repo
  alias Veriti.TitleSubmissions.TitleSubmission

  def list_user_submissions(user_id) do
    TitleSubmission
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def create_submission(attrs) do
    %TitleSubmission{}
    |> TitleSubmission.changeset(attrs)
    |> Repo.insert()
  end
end
