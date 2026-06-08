defmodule VeritiWeb.ErrorHTMLTest do
  use VeritiWeb.ConnCase, async: true

  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    html = render_to_string(VeritiWeb.ErrorHTML, "404", "html", [])
    assert html =~ "404"
    assert html =~ "Page not found"
    assert html =~ "Go to Home"
  end

  test "renders 500.html" do
    html = render_to_string(VeritiWeb.ErrorHTML, "500", "html", [])
    assert html =~ "500"
    assert html =~ "Something went wrong"
    assert html =~ "Go to Home"
  end
end
