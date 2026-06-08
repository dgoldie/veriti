defmodule Veriti.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      VeritiWeb.Telemetry,
      Veriti.Repo,
      {DNSCluster, query: Application.get_env(:veriti, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Veriti.PubSub},
      {Task.Supervisor, name: Veriti.TaskSupervisor},
      VeritiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Veriti.Supervisor]
    result = Supervisor.start_link(children, opts)
    if Mix.env() == :dev, do: Application.ensure_all_started(:tidewave)
    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VeritiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
