defmodule VeritiWeb.TitleSubmissionLiveTest do
  use VeritiWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Veriti.AccountsFixtures

  alias Veriti.{TitleSubmissions, Accounts}

  # Minimal 1×1 white PNG bytes (valid file the upload component will accept)
  @test_png <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0,
              0, 1, 8, 2, 0, 0, 0, 144, 119, 83, 222, 0, 0, 0, 12, 73, 68, 65, 84, 8, 215, 99,
              248, 207, 192, 0, 0, 0, 2, 0, 1, 226, 33, 188, 51, 0, 0, 0, 0, 73, 69, 78, 68,
              174, 66, 96, 130>>

  describe "home page" do
    test "renders CTA for unauthenticated visitor", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)
      assert html =~ "Get Started Free"
      assert html =~ "Log In"
      refute html =~ "Submit a Title"
    end

    test "renders CTA for authenticated user", %{conn: conn} do
      user = user_fixture()
      conn = conn |> log_in_user(user) |> get(~p"/")
      html = html_response(conn, 200)
      assert html =~ "Submit a Title"
      assert html =~ "My Submissions"
      refute html =~ "Get Started Free"
    end
  end

  describe "submissions index" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/submissions")
    end

    test "shows empty state for new user", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/submissions")
      assert html =~ "No submissions yet"
    end

    test "lists existing submissions", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _sub} =
        TitleSubmissions.create_submission(%{
          file_path: "/tmp/test.png",
          original_filename: "my-title.png",
          content_type: "image/png",
          user_id: user.id
        })

      {:ok, _view, html} = live(conn, ~p"/submissions")
      assert html =~ "my-title.png"
      assert html =~ "pending"
    end

    test "shows View link for each submission", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, sub} =
        TitleSubmissions.create_submission(%{
          file_path: "/tmp/test.png",
          original_filename: "title.png",
          content_type: "image/png",
          user_id: user.id
        })

      {:ok, _view, html} = live(conn, ~p"/submissions")
      assert html =~ ~p"/submissions/#{sub.id}"
    end
  end

  describe "submission new form" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/submissions/new")
    end

    test "renders upload form for authenticated user", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/submissions/new")
      assert html =~ "Submit a Vehicle Title"
      assert html =~ "Click to upload"
      assert html =~ "JPG, PNG, or PDF up to 10MB"
    end

    test "uploads file and submits, redirecting to submissions list", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/submissions/new")

      image =
        file_input(view, "#upload-form", :title_image, [
          %{
            last_modified: 1_594_171_879_000,
            name: "title.png",
            content: @test_png,
            size: byte_size(@test_png),
            type: "image/png"
          }
        ])

      assert render_upload(image, "title.png", 100) =~ "title.png"

      view |> form("#upload-form") |> render_submit()

      assert_redirect(view, ~p"/submissions")

      # Submission was created in DB
      assert [sub] = TitleSubmissions.list_user_submissions(user.id)
      assert sub.original_filename == "title.png"
      assert sub.status in ["pending", "processing", "completed", "failed"]
    end

    test "shows error when no file selected", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/submissions/new")
      html = view |> form("#upload-form") |> render_submit()
      assert html =~ "Please select a file"
    end
  end

  describe "submission show" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/submissions/999")
    end

    test "shows 404 for another user's submission", %{conn: conn} do
      user = user_fixture()
      other = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, sub} =
        TitleSubmissions.create_submission(%{
          file_path: "/tmp/test.png",
          original_filename: "other.png",
          content_type: "image/png",
          user_id: other.id
        })

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/submissions/#{sub.id}")
      end
    end

    test "shows validation in progress for pending submission", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, sub} =
        TitleSubmissions.create_submission(%{
          file_path: "/tmp/test.png",
          original_filename: "title.png",
          content_type: "image/png",
          user_id: user.id
        })

      {:ok, _view, html} = live(conn, ~p"/submissions/#{sub.id}")
      assert html =~ "Validation in progress"
    end
  end

  describe "admin dashboard" do
    test "redirects non-admin to home", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin")
    end

    test "renders for admin user", %{conn: conn} do
      user = user_fixture()
      {:ok, admin} = Accounts.grant_admin(user)
      conn = log_in_user(conn, admin)
      {:ok, _view, html} = live(conn, ~p"/admin")
      assert html =~ "Admin Dashboard"
      assert html =~ "Export CSV"
    end
  end
end
