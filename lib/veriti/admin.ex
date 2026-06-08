defmodule Veriti.Admin do
  import Ecto.Query

  alias Veriti.Repo
  alias Veriti.TitleSubmissions.TitleSubmission

  @doc """
  Lists all submissions across all users, optionally filtered.
  Preloads :user and :validation_result.

  Accepted filter keys: "status" (any submission status or "all"),
  "date_range" ("all" | "today" | "7d" | "30d").
  """
  def list_submissions(filters \\ %{}) do
    TitleSubmission
    |> apply_filters(filters)
    |> order_by(desc: :inserted_at)
    |> preload([:user, :validation_result])
    |> Repo.all()
  end

  @doc "Returns a map of %{status => count} for all submissions."
  def submission_stats do
    TitleSubmission
    |> group_by([s], s.status)
    |> select([s], {s.status, count(s.id)})
    |> Repo.all()
    |> Map.new()
  end

  defp apply_filters(query, filters) do
    query
    |> filter_by_status(filters["status"])
    |> filter_by_date(filters["date_range"])
  end

  defp filter_by_status(query, s) when s in [nil, "", "all"], do: query
  defp filter_by_status(query, status), do: where(query, status: ^status)

  defp filter_by_date(query, r) when r in [nil, "", "all"], do: query

  defp filter_by_date(query, "today") do
    start = DateTime.new!(Date.utc_today(), ~T[00:00:00])
    where(query, [s], s.inserted_at >= ^start)
  end

  defp filter_by_date(query, "7d") do
    cutoff = DateTime.add(DateTime.utc_now(), -7, :day)
    where(query, [s], s.inserted_at >= ^cutoff)
  end

  defp filter_by_date(query, "30d") do
    cutoff = DateTime.add(DateTime.utc_now(), -30, :day)
    where(query, [s], s.inserted_at >= ^cutoff)
  end

  defp filter_by_date(query, _), do: query
end
