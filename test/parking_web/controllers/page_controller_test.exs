defmodule ParkingWeb.PageControllerTest do
  use ParkingWeb.ConnCase

  test "GET /", %{conn: conn} do
    # Create a test garage first
    {:ok, garage} = Parking.Repo.insert(%Parking.ParkingGarage{name: "Test Garage"})

    # Create pricing for the garage
    pricing = Parking.Repo.insert!(%Parking.Pricing{garage_id: garage.id, type: "time_based"})
    Parking.Repo.insert!(%Parking.Pricing.TimeBasedConfig{pricing_id: pricing.id, rate_per_hour: 3.0})

    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Parksystem"
  end
end
