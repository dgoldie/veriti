defmodule VeritiWeb.TitleSubmissionLive.Index do
  use VeritiWeb, :live_view

  alias Veriti.TitleSubmissions

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    submissions = TitleSubmissions.list_user_submissions(user.id)
    {:ok, assign(socket, :submissions, submissions)}
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

        <%= if @submissions == [] do %>
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
                </tr>
              </thead>
              <tbody>
                <%= for sub <- @submissions do %>
                  <tr>
                    <td class="font-medium">{sub.original_filename}</td>
                    <td>
                      <span class={["badge", status_badge_class(sub.status)]}>
                        {sub.status}
                      </span>
                    </td>
                    <td class="text-base-content/60 text-sm">
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

  defp status_badge_class("pending"), do: "badge-warning"
  defp status_badge_class("processing"), do: "badge-info"
  defp status_badge_class("completed"), do: "badge-success"
  defp status_badge_class("failed"), do: "badge-error"
  defp status_badge_class(_), do: "badge-ghost"
end
