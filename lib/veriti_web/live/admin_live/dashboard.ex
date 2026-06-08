defmodule VeritiWeb.AdminLive.Dashboard do
  use VeritiWeb, :live_view

  alias Veriti.Admin

  @default_filters %{"status" => "all", "date_range" => "all"}

  @impl true
  def mount(_params, _session, socket) do
    submissions = Admin.list_submissions(@default_filters)
    stats = Admin.submission_stats()

    {:ok,
     assign(socket,
       submissions: submissions,
       stats: stats,
       filters: @default_filters
     )}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters = Map.take(params, ["status", "date_range"])
    submissions = Admin.list_submissions(filters)
    {:noreply, assign(socket, submissions: submissions, filters: filters)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-6xl">
        <.header>
          Admin Dashboard
          <:subtitle>All title submissions across all users</:subtitle>
          <:actions>
            <a
              href={export_url(@filters)}
              class="btn btn-outline btn-sm"
              download
            >
              Export CSV
            </a>
          </:actions>
        </.header>

        <%!-- Stats --%>
        <div class="grid grid-cols-2 sm:grid-cols-5 gap-3 mt-8">
          <.stat_card label="Total" value={total_count(@stats)} class="col-span-1" />
          <.stat_card label="Pending" value={Map.get(@stats, "pending", 0)} badge_class="badge-warning" />
          <.stat_card label="Processing" value={Map.get(@stats, "processing", 0)} badge_class="badge-info" />
          <.stat_card label="Completed" value={Map.get(@stats, "completed", 0)} badge_class="badge-success" />
          <.stat_card label="Failed" value={Map.get(@stats, "failed", 0)} badge_class="badge-error" />
        </div>

        <%!-- Filters --%>
        <form phx-change="filter" class="flex flex-wrap items-center gap-3 mt-8">
          <select name="status" class="select select-bordered select-sm">
            <option value="all" selected={@filters["status"] == "all"}>All statuses</option>
            <option value="pending" selected={@filters["status"] == "pending"}>Pending</option>
            <option value="processing" selected={@filters["status"] == "processing"}>Processing</option>
            <option value="completed" selected={@filters["status"] == "completed"}>Completed</option>
            <option value="failed" selected={@filters["status"] == "failed"}>Failed</option>
          </select>

          <select name="date_range" class="select select-bordered select-sm">
            <option value="all" selected={@filters["date_range"] == "all"}>All time</option>
            <option value="today" selected={@filters["date_range"] == "today"}>Today</option>
            <option value="7d" selected={@filters["date_range"] == "7d"}>Last 7 days</option>
            <option value="30d" selected={@filters["date_range"] == "30d"}>Last 30 days</option>
          </select>

          <span class="text-sm text-base-content/50">
            {length(@submissions)} submission{if length(@submissions) != 1, do: "s", else: ""}
          </span>
        </form>

        <%!-- Table --%>
        <%= if @submissions == [] do %>
          <div class="text-center py-16 text-base-content/50">
            <p>No submissions match the selected filters.</p>
          </div>
        <% else %>
          <div class="overflow-x-auto mt-4">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th>User</th>
                  <th>File</th>
                  <th>Status</th>
                  <th>VIN</th>
                  <th>Validation</th>
                  <th>Submitted</th>
                </tr>
              </thead>
              <tbody>
                <%= for sub <- @submissions do %>
                  <tr>
                    <td class="text-sm text-base-content/70">{sub.user.email}</td>
                    <td class="font-medium max-w-48 truncate">{sub.original_filename}</td>
                    <td>
                      <span class={["badge badge-sm", submission_badge_class(sub.status)]}>
                        {sub.status}
                      </span>
                    </td>
                    <td class="font-mono text-xs">
                      {(sub.validation_result && sub.validation_result.extracted_vin) || "—"}
                    </td>
                    <td>
                      <%= if sub.validation_result do %>
                        <span class={["badge badge-sm", validation_badge_class(sub.validation_result.overall_status)]}>
                          {sub.validation_result.overall_status}
                        </span>
                      <% else %>
                        <span class="text-base-content/40 text-xs">—</span>
                      <% end %>
                    </td>
                    <td class="text-sm text-base-content/60 whitespace-nowrap">
                      {Calendar.strftime(sub.inserted_at, "%b %d, %Y")}
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  attr :label, :string, required: true
  attr :value, :integer, required: true
  attr :badge_class, :string, default: nil
  attr :class, :string, default: nil

  defp stat_card(assigns) do
    ~H"""
    <div class={["stat bg-base-200 rounded-box p-4", @class]}>
      <div class="flex items-center justify-between">
        <div class="stat-title text-xs">{@label}</div>
        <%= if @badge_class do %>
          <span class={["badge badge-xs", @badge_class]}></span>
        <% end %>
      </div>
      <div class="stat-value text-2xl mt-1">{@value}</div>
    </div>
    """
  end

  defp total_count(stats), do: stats |> Map.values() |> Enum.sum()

  defp submission_badge_class("pending"), do: "badge-warning"
  defp submission_badge_class("processing"), do: "badge-info"
  defp submission_badge_class("completed"), do: "badge-success"
  defp submission_badge_class("failed"), do: "badge-error"
  defp submission_badge_class(_), do: "badge-ghost"

  defp validation_badge_class("pass"), do: "badge-success"
  defp validation_badge_class("fail"), do: "badge-error"
  defp validation_badge_class("warning"), do: "badge-warning"
  defp validation_badge_class(_), do: "badge-ghost"

  defp export_url(filters) do
    params =
      filters
      |> Enum.reject(fn {_, v} -> v == "all" end)
      |> URI.encode_query()

    if params == "", do: "/admin/submissions/export.csv", else: "/admin/submissions/export.csv?#{params}"
  end
end
