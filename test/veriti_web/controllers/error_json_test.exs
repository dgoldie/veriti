defmodule VeritiWeb.ErrorJSONTest do
  use VeritiWeb.ConnCase, async: true

  test "renders 404" do
    assert VeritiWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert VeritiWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
