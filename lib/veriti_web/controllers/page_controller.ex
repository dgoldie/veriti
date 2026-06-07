defmodule VeritiWeb.PageController do
  use VeritiWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
