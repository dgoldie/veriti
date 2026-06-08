defmodule Veriti.RateLimiter do
  use GenServer

  @max_submissions_per_hour 10
  @window_seconds 3_600

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc "Returns :ok or {:error, :rate_limited} for a submission attempt by user_id."
  def check_submission(user_id) do
    GenServer.call(__MODULE__, {:check, :submission, user_id})
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:check, action, user_id}, _from, state) do
    now = System.os_time(:second)
    window_start = now - @window_seconds
    key = {action, user_id}

    recent =
      state
      |> Map.get(key, [])
      |> Enum.filter(&(&1 >= window_start))

    limit = limit_for(action)

    if length(recent) >= limit do
      {:reply, {:error, :rate_limited}, Map.put(state, key, recent)}
    else
      {:reply, :ok, Map.put(state, key, [now | recent])}
    end
  end

  defp limit_for(:submission), do: @max_submissions_per_hour
end
