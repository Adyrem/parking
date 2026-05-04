defmodule ParkingWeb.PageControllerTest do
  use ParkingWeb.ConnCase

  test "GET /", %{conn: conn} do
    # Create a test garage first
    {:ok, garage} = Parking.Repo.insert(%Parking.ParkingGarage{name: "Test Garage"})

    # Create pricing for the garage using the key format the implementation expects
    {:ok, _pricing} =
      Parking.Repo.insert(%Parking.Pricing{
        garage_id: garage.id,
        type: "time_based",
        config: %{
          "rate_per_hour" => 3.0,
          "daily_rate" => 35.0,
          "time_slots" => [
            %{"from" => "06:00", "to" => "18:00", "rate_per_hour" => 3.60},
            %{"from" => "18:00", "to" => "21:00", "rate_per_hour" => 2.80},
            %{"from" => "21:00", "to" => "24:00", "rate_per_hour" => 2.40}
          ]
        }
      })

    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Parksystem"
  end
end
