defmodule ParkingWeb.PageController do
  use ParkingWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
