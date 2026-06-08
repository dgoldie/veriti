defmodule VeritiWeb.TitleSubmissionLive.Index do
  use VeritiWeb, :live_view

  alias Veriti.TitleSubmissions

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Veriti.PubSub, "submissions:user:#{user.id}")
    end

    {:ok, load_page(socket, user, 1)}
  end

  @impl true
  def handle_info(:validation_complete, socket) do
    user = socket.assigns.current_scope.user
    {:noreply, load_page(socket, user, socket.assigns.page)}
  end

  @impl true
  def handle_event("goto-page", %{"page" => page}, socket) do
    user = socket.assigns.current_scope.user
    {:noreply, load_page(socket, user, String.to_integer(page))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl">
        <.header>
          My Submissions
          <:actions>
            <.link navigate={~p"/submissions/new"}>
              <.button variant="primary">Submit a Title</.button>
            </.link>
          </:actions>
        </.header>

        <%= if @total == 0 do %>
          <div class="text-center py-16 text-base-content/50">
            <p class="text-lg">No submissions yet.</p>
            <p class="mt-1 text-sm">
              <.link navigate={~p"/submissions/new"} class="link link-primary">Submit your first title</.link>
              to get started.
            </p>
          </div>
        <% else %>
          <div class="overflow-x-auto mt-6">
            <table class="table">
              <thead>
                <tr>
                  <th>File</th>
                  <th>Status</th>
                  <th>Submitted</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <%= for sub <- @submissions do %>
                  <tr>
                    <td class="font-medium">{sub.original_filename}</td>
                    <td>
                      <span class={["badge", status_badge_class(sub.status)]}>
                        {sub.status}
                        <%= if sub.status in ["pending", "processing"] do %>
                          <span class="loading loading-spinner loading-xs ml-1"></span>
                        <% end %>
                      </span>
                    </td>
                    <td class="text-base-content/60 text-sm">
                      {Calendar.strftime(sub.inserted_at, "%b %d, %Y")}
                    </td>
                    <td class="text-right">
                      <.link navigate={~p"/submissions/#{sub.id}"} class="btn btn-ghost btn-xs">
                        View
                      </.link>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>

          <%= if @total_pages > 1 do %>
            <div class="flex items-center justify-between mt-6">
              <button
                class="btn btn-outline btn-sm"
                phx-click="goto-page"
                phx-value-page={@page - 1}
                disabled={@page <= 1}
              >
                ← Previous
              </button>
              <span class="text-sm text-base-content/60">
                Page {@page} of {@total_pages}
              </span>
              <button
                class="btn btn-outline btn-sm"
                phx-click="goto-page"
                phx-value-page={@page + 1}
                disabled={@page >= @total_pages}
              >
                Next →
              </button>
            </div>
          <% end %>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp load_page(socket, user, page) do
    total = TitleSubmissions.count_user_submissions(user.id)
    total_pages = max(1, ceil(total / @per_page))
    page = min(page, total_pages)
    submissions = TitleSubmissions.list_user_submissions(user.id, page)

    assign(socket, submissions: submissions, page: page, total: total, total_pages: total_pages)
  end

  defp status_badge_class("pending"), do: "badge-warning"
  defp status_badge_class("processing"), do: "badge-info"
  defp status_badge_class("completed"), do: "badge-success"
  defp status_badge_class("failed"), do: "badge-error"
  defp status_badge_class(_), do: "badge-ghost"
end
