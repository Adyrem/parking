defmodule Parking.GarageStatsTest do
  use Parking.DataCase

  alias Parking.GarageStats
  alias Parking.Repo
  alias Parking.ParkingGarage
  alias Parking.Pricing
  alias Parking.Pricing.TimeBasedConfig
  alias Parking.Ticket
  alias Parking.ParkingSpot
  alias Parking.Level

  setup do
    {:ok, garage} = Repo.insert(%ParkingGarage{name: "Test Garage"})
    level = Repo.insert!(%Level{number: 1, garage_id: garage.id})

    pricing = Repo.insert!(%Pricing{garage_id: garage.id, type: "time_based"})
    Repo.insert!(%TimeBasedConfig{pricing_id: pricing.id, rate_per_hour: 3.0})

    spots = Enum.map(1..5, fn n -> Repo.insert!(%ParkingSpot{number: n, level_id: level.id}) end)

    Enum.each(Enum.take(spots, 2), fn spot ->
      Repo.insert!(%Ticket{
        entry_time: DateTime.utc_now() |> DateTime.truncate(:second),
        spot_id: spot.id,
        pricing_id: pricing.id
      })
    end)

    %{garage: garage}
  end

  test "get_garage_stats returns correct statistics", %{garage: garage} do
    stats = GarageStats.get_garage_stats(garage.id)
    assert stats.total_spots == 5
    assert stats.occupied_spots == 2
    assert stats.available_spots == 3
    assert stats.occupancy_rate == 40.0
  end

  test "get_garage_stats returns nil for unknown garage" do
    assert GarageStats.get_garage_stats(999_999) == nil
  end
end
