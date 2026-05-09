defmodule Parking.GuestParkingTest do
  use Parking.DataCase

  import Ecto.Query

  alias Parking.GuestParking
  alias Parking.Repo
  alias Parking.ParkingGarage
  alias Parking.Pricing
  alias Parking.Pricing.TimeBasedConfig
  alias Parking.Pricing.DailyRateConfig
  alias Parking.Ticket
  alias Parking.Payment
  alias Parking.ParkingSpot
  alias Parking.Level
  alias Parking.Users.PermanentUser

  defp insert_time_based_pricing(garage_id) do
    pricing = Repo.insert!(%Pricing{garage_id: garage_id, type: "time_based"})
    Repo.insert!(%TimeBasedConfig{pricing_id: pricing.id, rate_per_hour: 3.0})

    daily = Repo.insert!(%Pricing{garage_id: garage_id, type: "daily_rate"})
    Repo.insert!(%DailyRateConfig{pricing_id: daily.id, daily_rate: 35.0})

    pricing
  end

  defp active_ticket_exists?(spot_id) do
    Repo.exists?(from t in Ticket, where: t.spot_id == ^spot_id and is_nil(t.exit_time))
  end

  defp payment_exists?(ticket_id) do
    Repo.exists?(from p in Payment, where: p.ticket_id == ^ticket_id)
  end

  describe "guest parking workflow" do
    setup do
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Test Garage"})
      level = Repo.insert!(%Level{number: 1, garage_id: garage.id})
      spot1 = Repo.insert!(%ParkingSpot{number: 1, level_id: level.id})
      spot2 = Repo.insert!(%ParkingSpot{number: 2, level_id: level.id})
      pricing = insert_time_based_pricing(garage.id)
      %{garage: garage, pricing: pricing, spots: [spot1, spot2]}
    end

    test "guest enters parking successfully", %{garage: garage, pricing: pricing} do
      assert {:ok, ticket} = GuestParking.create_ticket(garage.id, pricing.id)
      assert ticket.spot_id
      assert ticket.entry_time
      refute payment_exists?(ticket.id)
      assert ticket.pricing_id == pricing.id
      assert active_ticket_exists?(ticket.spot_id)
    end

    test "guest cannot enter when no spots available", %{
      garage: garage,
      pricing: pricing,
      spots: spots
    } do
      Enum.each(spots, fn spot ->
        Repo.insert!(%Ticket{
          entry_time: DateTime.utc_now() |> DateTime.truncate(:second),
          spot_id: spot.id,
          pricing_id: pricing.id
        })
      end)

      assert {:error, :no_available_spots} = GuestParking.create_ticket(garage.id, pricing.id)
    end

    test "guest pays and exits successfully", %{garage: garage, pricing: pricing} do
      {:ok, ticket} = GuestParking.create_ticket(garage.id, pricing.id)
      {:ok, paid_ticket} = GuestParking.process_payment(ticket)
      {:ok, exited_ticket} = GuestParking.register_exit(paid_ticket)

      assert exited_ticket.exit_time
      assert payment_exists?(exited_ticket.id)
      refute active_ticket_exists?(exited_ticket.spot_id)
    end

    test "pay then exit workflow", %{garage: garage, pricing: pricing} do
      {:ok, ticket} = GuestParking.create_ticket(garage.id, pricing.id)
      {:ok, paid_ticket} = GuestParking.process_payment(ticket)
      assert payment_exists?(paid_ticket.id)

      {:ok, exited_ticket} = GuestParking.register_exit(paid_ticket)
      assert exited_ticket.exit_time
      refute active_ticket_exists?(exited_ticket.spot_id)
    end

    test "guest cannot exit without paying", %{garage: garage, pricing: pricing} do
      {:ok, ticket} = GuestParking.create_ticket(garage.id, pricing.id)
      assert {:error, :payment_required} = GuestParking.register_exit(ticket)
      assert active_ticket_exists?(ticket.spot_id)
    end
  end

  describe "payment service failure" do
    setup do
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Test Garage"})
      level = Repo.insert!(%Level{number: 1, garage_id: garage.id})
      Repo.insert!(%ParkingSpot{number: 1, level_id: level.id})
      pricing = insert_time_based_pricing(garage.id)

      Application.put_env(:parking, :payment_service, Parking.Services.PaymentService.FailingStub)
      on_exit(fn -> Application.delete_env(:parking, :payment_service) end)

      %{garage: garage, pricing: pricing}
    end

    test "payment failure returns error and leaves ticket unpaid", %{
      garage: garage,
      pricing: pricing
    } do
      {:ok, ticket} = GuestParking.create_ticket(garage.id, pricing.id)
      assert {:error, :payment_failed} = GuestParking.process_payment(ticket)
      refute payment_exists?(ticket.id)
      assert active_ticket_exists?(ticket.spot_id)
    end
  end

  describe "balanced spot assignment" do
    setup do
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Test Garage"})
      level1 = Repo.insert!(%Level{number: 1, garage_id: garage.id})
      level2 = Repo.insert!(%Level{number: 2, garage_id: garage.id})

      Enum.each(1..3, fn n -> Repo.insert!(%ParkingSpot{number: n, level_id: level1.id}) end)
      Enum.each(1..3, fn n -> Repo.insert!(%ParkingSpot{number: n, level_id: level2.id}) end)

      pricing = insert_time_based_pricing(garage.id)
      %{garage: garage, level1: level1, level2: level2, pricing: pricing}
    end

    test "first two tickets land on different levels", %{garage: garage, pricing: pricing} do
      {:ok, t1} = GuestParking.create_ticket(garage.id, pricing.id)
      {:ok, t2} = GuestParking.create_ticket(garage.id, pricing.id)

      spot1 = Repo.get!(ParkingSpot, t1.spot_id)
      spot2 = Repo.get!(ParkingSpot, t2.spot_id)

      assert spot1.level_id != spot2.level_id,
             "Expected tickets on different levels, both on level_id=#{spot1.level_id}"
    end

    test "spots are spread across levels rather than stacking on one", %{
      garage: garage,
      level1: level1,
      level2: level2,
      pricing: pricing
    } do
      level_ids =
        Enum.map(1..4, fn _ ->
          {:ok, t} = GuestParking.create_ticket(garage.id, pricing.id)
          Repo.get!(ParkingSpot, t.spot_id).level_id
        end)

      level1_count = Enum.count(level_ids, &(&1 == level1.id))
      level2_count = Enum.count(level_ids, &(&1 == level2.id))

      assert level1_count == 2 and level2_count == 2,
             "Expected 2 spots per level, got level1=#{level1_count}, level2=#{level2_count}"
    end
  end

  describe "reservation-aware spot assignment" do
    setup do
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Test Garage"})
      level1 = Repo.insert!(%Level{number: 1, garage_id: garage.id})
      level2 = Repo.insert!(%Level{number: 2, garage_id: garage.id})

      [l1s1, l1s2, _l1s3] =
        Enum.map(1..3, fn n -> Repo.insert!(%ParkingSpot{number: n, level_id: level1.id}) end)

      Enum.each(1..3, fn n -> Repo.insert!(%ParkingSpot{number: n, level_id: level2.id}) end)

      Enum.each([l1s1, l1s2], fn spot ->
        {:ok, user} = Repo.insert(%Parking.Users.User{type: "permanent"})

        Repo.insert!(%PermanentUser{
          id: user.id,
          name: "Perm User",
          access_code: Ecto.UUID.generate(),
          is_blocked: false,
          spot_id: spot.id
        })
      end)

      pricing = insert_time_based_pricing(garage.id)
      %{garage: garage, level1: level1, level2: level2, pricing: pricing}
    end

    test "guests prefer the level with fewer reservations", %{
      garage: garage,
      level2: level2,
      pricing: pricing
    } do
      {:ok, ticket} = GuestParking.create_ticket(garage.id, pricing.id)
      spot = Repo.get!(ParkingSpot, ticket.spot_id)

      assert spot.level_id == level2.id,
             "Expected first guest on level2 (no reservations), got level_id=#{spot.level_id}"
    end
  end

  describe "guest parking status" do
    setup do
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Test Garage"})
      level = Repo.insert!(%Level{number: 1, garage_id: garage.id})
      pricing = insert_time_based_pricing(garage.id)

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

    test "shows correct availability", %{garage: garage} do
      status = GuestParking.guest_parking_status(garage.id)
      assert status.total_spots == 5
      assert status.available_spots == 3
      assert status.occupied_spots == 2
      assert status.occupancy_rate == 40.0
    end
  end
end
