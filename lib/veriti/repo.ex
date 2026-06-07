defmodule Veriti.Repo do
  use Ecto.Repo,
    otp_app: :veriti,
    adapter: Ecto.Adapters.Postgres
end
