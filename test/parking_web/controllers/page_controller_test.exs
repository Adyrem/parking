defmodule ParkingWeb.PageControllerTest do
  use ParkingWeb.ConnCase

  test "GET /", %{conn: conn} do
    # Create a test garage first
    {:ok, garage} = Parking.Repo.insert(%Parking.ParkingGarage{name: "Test Garage"})

    # Create pricing for the garage
    {:ok, _pricing} =
      Parking.Repo.insert(%Parking.Pricing{
        garage_id: garage.id,
        type: "time_based",
        config: %{
          "base_rate" => 2.0,
          "hourly_rate" => 3.0,
          "daily_rate" => 20.0,
          "time_slots" => [
            %{"start_time" => "06:00", "end_time" => "18:00", "rate" => 3.0},
            %{"start_time" => "18:00", "end_time" => "22:00", "rate" => 4.0},
            %{"start_time" => "22:00", "end_time" => "06:00", "rate" => 2.0}
          ],
          "weekend_multiplier" => 1.5,
          "holiday_multiplier" => 2.0,
          "quarter_hour_billing" => true
        }
      })

    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Parksystem"
  end
end
