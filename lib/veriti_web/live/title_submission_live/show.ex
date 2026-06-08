defmodule VeritiWeb.TitleSubmissionLive.Show do
  use VeritiWeb, :live_view

  alias Veriti.{TitleSubmissions, Validation}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_scope.user
    submission = TitleSubmissions.get_user_submission!(user.id, id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Veriti.PubSub, "submission:#{submission.id}")
    end

    result =
      if submission.status in ["completed", "failed"],
        do: Validation.get_result_for_submission(submission.id),
        else: nil

    {:ok, assign(socket, submission: submission, result: result)}
  end

  @impl true
  def handle_info(:validation_complete, socket) do
    user = socket.assigns.current_scope.user
    submission = TitleSubmissions.get_user_submission!(user.id, socket.assigns.submission.id)
    result = Validation.get_result_for_submission(submission.id)
    {:noreply, assign(socket, submission: submission, result: result)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl">
        <.header>
          {Path.basename(@submission.original_filename)}
          <:subtitle>
            Submitted {Calendar.strftime(@submission.inserted_at, "%B %d, %Y at %I:%M %p")}
          </:subtitle>
          <:actions>
            <.link navigate={~p"/submissions"} class="btn btn-ghost btn-sm">
              ← Back
            </.link>
          </:actions>
        </.header>

        <div class="mt-8 space-y-6">
          <%= cond do %>
            <% @submission.status in ["pending", "processing"] -> %>
              <div class="card bg-base-200">
                <div class="card-body items-center text-center py-12">
                  <span class="loading loading-spinner loading-lg text-primary"></span>
                  <p class="mt-4 font-semibold">Validation in progress</p>
                  <p class="text-sm text-base-content/60">
                    OCR extraction and field validation are running.
                    This page will update automatically.
                  </p>
                </div>
              </div>

            <% @result == nil -> %>
              <div class="alert alert-warning">
                <span class="hero-exclamation-triangle size-5"></span>
                <span>Validation result not available for this submission.</span>
              </div>

            <% true -> %>
              <%!-- Overall status banner --%>
              <div class={["alert", overall_alert_class(@result.overall_status)]}>
                <span class={overall_icon_class(@result.overall_status)}></span>
                <div>
                  <p class="font-semibold">{overall_label(@result.overall_status)}</p>
                  <p class="text-sm opacity-80">{overall_description(@result.overall_status)}</p>
                </div>
              </div>

              <%!-- Issues list --%>
              <%= if @result.issues != [] do %>
                <div class="card bg-base-200">
                  <div class="card-body">
                    <h3 class="card-title text-base">Issues Found</h3>
                    <ul class="space-y-1 mt-1">
                      <%= for issue <- @result.issues do %>
                        <li class="flex items-start gap-2 text-sm">
                          <span class="hero-exclamation-circle size-4 mt-0.5 shrink-0 text-warning"></span>
                          {issue}
                        </li>
                      <% end %>
                    </ul>
                  </div>
                </div>
              <% end %>

              <%!-- Extracted fields table --%>
              <div class="card bg-base-200">
                <div class="card-body">
                  <h3 class="card-title text-base">Extracted Fields</h3>
                  <div class="overflow-x-auto mt-2">
                    <table class="table table-sm">
                      <thead>
                        <tr>
                          <th>Field</th>
                          <th>Value</th>
                          <th>Check</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr>
                          <td class="font-medium text-base-content/70">VIN</td>
                          <td class="font-mono">{@result.extracted_vin || "—"}</td>
                          <td><.check_badge status={@result.vin_status} /></td>
                        </tr>
                        <tr>
                          <td class="font-medium text-base-content/70">Title Number</td>
                          <td class="font-mono">{@result.extracted_title_number || "—"}</td>
                          <td><.check_badge status={@result.title_number_status} /></td>
                        </tr>
                        <tr>
                          <td class="font-medium text-base-content/70">Lienholder</td>
                          <td>{@result.extracted_lienholder || "—"}</td>
                          <td><.lien_badge status={@result.lien_status} /></td>
                        </tr>
                        <tr>
                          <td class="font-medium text-base-content/70">Owner</td>
                          <td>{@result.extracted_owner || "—"}</td>
                          <td></td>
                        </tr>
                        <tr>
                          <td class="font-medium text-base-content/70">Odometer</td>
                          <td>
                            <%= if @result.extracted_odometer do %>
                              {format_miles(@result.extracted_odometer)} mi
                            <% else %>
                              —
                            <% end %>
                          </td>
                          <td></td>
                        </tr>
                        <tr>
                          <td class="font-medium text-base-content/70">State</td>
                          <td>{@result.extracted_state || "—"}</td>
                          <td></td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :status, :string, required: true

  defp check_badge(%{status: "pass"} = assigns) do
    ~H"""
    <span class="badge badge-success badge-sm gap-1">
      <span class="hero-check-circle size-3"></span> Pass
    </span>
    """
  end

  defp check_badge(%{status: "fail"} = assigns) do
    ~H"""
    <span class="badge badge-error badge-sm gap-1">
      <span class="hero-x-circle size-3"></span> Fail
    </span>
    """
  end

  defp check_badge(%{status: "warning"} = assigns) do
    ~H"""
    <span class="badge badge-warning badge-sm gap-1">
      <span class="hero-exclamation-triangle size-3"></span> Warning
    </span>
    """
  end

  defp check_badge(%{status: _} = assigns) do
    ~H"""
    <span class="badge badge-ghost badge-sm">Not detected</span>
    """
  end

  attr :status, :string, required: true

  defp lien_badge(%{status: "detected"} = assigns) do
    ~H"""
    <span class="badge badge-warning badge-sm gap-1">
      <span class="hero-exclamation-triangle size-3"></span> Detected
    </span>
    """
  end

  defp lien_badge(assigns) do
    ~H"""
    <span class="badge badge-success badge-sm gap-1">
      <span class="hero-check-circle size-3"></span> None
    </span>
    """
  end

  defp overall_alert_class("pass"), do: "alert-success"
  defp overall_alert_class("fail"), do: "alert-error"
  defp overall_alert_class("warning"), do: "alert-warning"
  defp overall_alert_class(_), do: "alert-info"

  defp overall_icon_class("pass"), do: "hero-check-circle size-6"
  defp overall_icon_class("fail"), do: "hero-x-circle size-6"
  defp overall_icon_class(_), do: "hero-exclamation-triangle size-6"

  defp overall_label("pass"), do: "Validation Passed"
  defp overall_label("fail"), do: "Validation Failed"
  defp overall_label("warning"), do: "Validation Passed with Warnings"
  defp overall_label(_), do: "Validation Complete"

  defp overall_description("pass"), do: "All checks passed. This title appears valid."
  defp overall_description("fail"), do: "One or more critical checks failed. Review the issues below."
  defp overall_description("warning"), do: "The title was processed but some fields need review."
  defp overall_description(_), do: ""

  defp format_miles(miles_str) do
    case Integer.parse(miles_str) do
      {n, _} ->
        n
        |> Integer.to_string()
        |> String.graphemes()
        |> Enum.reverse()
        |> Enum.chunk_every(3)
        |> Enum.join(",")
        |> String.graphemes()
        |> Enum.reverse()
        |> Enum.join()

      :error ->
        miles_str
    end
  end
end
