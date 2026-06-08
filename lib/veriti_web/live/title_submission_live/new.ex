defmodule VeritiWeb.TitleSubmissionLive.New do
  use VeritiWeb, :live_view

  alias Veriti.{TitleSubmissions, Validation}

  @max_file_size 10 * 1024 * 1024

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:uploaded_files, [])
      |> allow_upload(:title_image,
        accept: ~w(.jpg .jpeg .png .pdf),
        max_entries: 1,
        max_file_size: @max_file_size
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-2xl">
        <.header>
          Submit a Vehicle Title
          <:subtitle>Upload a photo or scan of the title for validation</:subtitle>
        </.header>

        <form id="upload-form" phx-submit="submit" phx-change="validate">
          <div
            class="border-2 border-dashed border-base-300 rounded-box p-8 text-center cursor-pointer hover:border-primary transition-colors"
            phx-drop-target={@uploads.title_image.ref}
          >
            <.live_file_input upload={@uploads.title_image} class="hidden" />
            <label for={@uploads.title_image.ref} class="cursor-pointer">
              <div class="flex flex-col items-center gap-3">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-base-content/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                </svg>
                <div>
                  <span class="font-semibold text-primary">Click to upload</span>
                  <span class="text-base-content/60"> or drag and drop</span>
                </div>
                <p class="text-sm text-base-content/40">JPG, PNG, or PDF up to 10MB</p>
              </div>
            </label>
          </div>

          <%= for entry <- @uploads.title_image.entries do %>
            <div class="mt-4 card bg-base-200">
              <div class="card-body p-4">
                <%= if String.starts_with?(entry.client_type, "image/") do %>
                  <.live_img_preview entry={entry} class="rounded-lg max-h-64 object-contain mx-auto" />
                <% else %>
                  <div class="flex items-center gap-3">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-error" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
                    </svg>
                    <span class="font-medium">{entry.client_name}</span>
                  </div>
                <% end %>

                <div class="flex items-center justify-between mt-2">
                  <span class="text-sm text-base-content/60">{entry.client_name}</span>
                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    class="btn btn-ghost btn-xs"
                  >
                    &times;
                  </button>
                </div>

                <progress class="progress progress-primary w-full" value={entry.progress} max="100" />

                <%= for err <- upload_errors(@uploads.title_image, entry) do %>
                  <p class="text-error text-sm mt-1">{error_to_string(err)}</p>
                <% end %>
              </div>
            </div>
          <% end %>

          <%= for err <- upload_errors(@uploads.title_image) do %>
            <p class="text-error text-sm mt-2">{error_to_string(err)}</p>
          <% end %>

          <div class="mt-6">
            <.button
              variant="primary"
              class="w-full"
              phx-disable-with="Submitting..."
              disabled={@uploads.title_image.entries == []}
            >
              Submit Title for Validation
            </.button>
          </div>
        </form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :title_image, ref)}
  end

  def handle_event("submit", _params, socket) do
    user = socket.assigns.current_scope.user
    uploads_dir = uploads_dir()
    File.mkdir_p!(uploads_dir)

    results =
      consume_uploaded_entries(socket, :title_image, fn %{path: tmp_path}, entry ->
        ext = Path.extname(entry.client_name)
        filename = "#{System.unique_integer([:positive, :monotonic])}#{ext}"
        dest = Path.join(uploads_dir, filename)
        File.cp!(tmp_path, dest)

        {:ok,
         %{
           file_path: dest,
           original_filename: entry.client_name,
           content_type: entry.client_type
         }}
      end)

    case results do
      [attrs] ->
        case TitleSubmissions.create_submission(Map.put(attrs, :user_id, user.id)) do
          {:ok, submission} ->
            Task.Supervisor.start_child(Veriti.TaskSupervisor, fn ->
              Validation.process(submission)
            end)

            {:noreply,
             socket
             |> put_flash(:info, "Title submitted. Validation is running in the background.")
             |> push_navigate(to: ~p"/submissions")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to save submission.")}
        end

      [] ->
        {:noreply, put_flash(socket, :error, "Please select a file before submitting.")}
    end
  end

  defp uploads_dir do
    Application.get_env(:veriti, :uploads_dir, Path.join([:code.priv_dir(:veriti), "uploads"]))
  end

  defp error_to_string(:too_large), do: "File exceeds the 10MB limit."
  defp error_to_string(:not_accepted), do: "Unsupported file type. Use JPG, PNG, or PDF."
  defp error_to_string(:too_many_files), do: "Only one file can be uploaded at a time."
  defp error_to_string(err), do: "Upload error: #{inspect(err)}"
end
