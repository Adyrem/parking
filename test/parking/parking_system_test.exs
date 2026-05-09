defmodule Parking.ParkingSystemTest do
  use Parking.DataCase

  import Ecto.Query

  alias Parking.ParkingSystem
  alias Parking.Repo
  alias Parking.ParkingGarage
  alias Parking.Pricing
  alias Parking.Pricing.TimeBasedConfig
  alias Parking.Pricing.DailyRateConfig
  alias Parking.Pricing.MonthlyRentConfig
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

  defp insert_monthly_rent_pricing(garage_id, monthly_rent) do
    pricing = Repo.insert!(%Pricing{garage_id: garage_id, type: "monthly_rent"})

    Repo.insert!(%MonthlyRentConfig{
      pricing_id: pricing.id,
      monthly_rent: monthly_rent
    })

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
      assert {:ok, ticket} = ParkingSystem.create_ticket(garage.id, pricing.id)

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
      # Occupy all spots with active tickets
      Enum.each(spots, fn spot ->
        Repo.insert!(%Ticket{
          entry_time: DateTime.utc_now() |> DateTime.truncate(:second),
          spot_id: spot.id,
          pricing_id: pricing.id
        })
      end)

      assert {:error, :no_available_spots} = ParkingSystem.create_ticket(garage.id, pricing.id)
    end

    test "guest pays and exits successfully", %{garage: garage, pricing: pricing} do
      {:ok, ticket} = ParkingSystem.create_ticket(garage.id, pricing.id)

      {:ok, paid_ticket} = ParkingSystem.process_payment(ticket)

      {:ok, exited_ticket} = ParkingSystem.register_exit(paid_ticket)

      assert exited_ticket.exit_time
      assert payment_exists?(exited_ticket.id)
      refute active_ticket_exists?(exited_ticket.spot_id)
    end

    test "pay then exit workflow", %{garage: garage, pricing: pricing} do
      {:ok, ticket} = ParkingSystem.create_ticket(garage.id, pricing.id)

      {:ok, paid_ticket} = ParkingSystem.process_payment(ticket)
      assert payment_exists?(paid_ticket.id)

      {:ok, exited_ticket} = ParkingSystem.register_exit(paid_ticket)
      assert exited_ticket.exit_time

      refute active_ticket_exists?(exited_ticket.spot_id)
    end

    # TC-12: Ausfahrt ohne Zahlung wird verweigert
    test "guest cannot exit without paying", %{garage: garage, pricing: pricing} do
      {:ok, ticket} = ParkingSystem.create_ticket(garage.id, pricing.id)
      assert {:error, :payment_required} = ParkingSystem.register_exit(ticket)

      assert active_ticket_exists?(ticket.spot_id)
    end
  end

  # TC-10: Bezahlung fehlgeschlagen
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
      {:ok, ticket} = ParkingSystem.create_ticket(garage.id, pricing.id)
      assert {:error, :payment_failed} = ParkingSystem.process_payment(ticket)

      refute payment_exists?(ticket.id)
      assert active_ticket_exists?(ticket.spot_id)
    end
  end

  describe "permanent user workflow" do
    setup do
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Test Garage"})

      level = Repo.insert!(%Level{number: 1, garage_id: garage.id})

      spot = Repo.insert!(%ParkingSpot{number: 1, level_id: level.id})

      {:ok, user} = Repo.insert(%Parking.Users.User{type: "permanent"})

      {:ok, perm_user} =
        Repo.insert(%Parking.Users.PermanentUser{
          id: user.id,
          name: "Test User",
          access_code: "123456",
          is_blocked: false,
          spot_id: spot.id
        })

      %{garage: garage, perm_user: perm_user, spot: spot}
    end

    test "permanent user authentication", %{perm_user: perm_user} do
      assert {:ok, authenticated_user} = ParkingSystem.authenticate_permanent_user("123456")
      assert authenticated_user.id == perm_user.id
    end

    test "permanent user authentication fails with wrong code", %{perm_user: _perm_user} do
      assert {:error, :not_found} = ParkingSystem.authenticate_permanent_user("wrong_code")
    end

    test "permanent user enters successfully", %{perm_user: perm_user} do
      {:ok, _updated_user} = ParkingSystem.enter_permanent_user(perm_user)

      ticket = Repo.get_by(Ticket, permanent_user_id: perm_user.id) |> Repo.preload(:spot)
      assert ticket
      assert ticket.spot_id == perm_user.spot_id
      refute ticket.exit_time

      assert active_ticket_exists?(perm_user.spot_id)
    end

    test "permanent user exits successfully", %{perm_user: perm_user} do
      {:ok, _} = ParkingSystem.enter_permanent_user(perm_user)

      {:ok, _updated_user} = ParkingSystem.exit_permanent_user(perm_user)

      ticket = Repo.get_by(Ticket, permanent_user_id: perm_user.id)
      assert ticket.exit_time

      refute active_ticket_exists?(perm_user.spot_id)
    end

    test "blocked permanent user cannot enter", %{perm_user: perm_user} do
      Repo.update!(PermanentUser.changeset(perm_user, %{is_blocked: true}))

      assert {:error, {:blocked, _}} = ParkingSystem.authenticate_permanent_user("123456")
    end
  end

  describe "permanent user creation" do
    test "returns error when no free spots are available" do
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Full Garage"})
      level = Repo.insert!(%Level{number: 1, garage_id: garage.id})
      spot = Repo.insert!(%ParkingSpot{number: 1, level_id: level.id})

      {:ok, user} = Repo.insert(%Parking.Users.User{type: "permanent"})

      Repo.insert!(%PermanentUser{
        id: user.id,
        name: "Existing User",
        access_code: Ecto.UUID.generate(),
        is_blocked: false,
        spot_id: spot.id
      })

      assert {:error, :no_spots} = ParkingSystem.create_permanent_user(garage.id, "New User")
    end

    test "creates permanent user with monthly rent from pricing sub-table" do
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Test Garage"})
      level = Repo.insert!(%Level{number: 1, garage_id: garage.id})
      Repo.insert!(%ParkingSpot{number: 1, level_id: level.id})
      insert_monthly_rent_pricing(garage.id, 100.0)

      assert {:ok, perm_user} = ParkingSystem.create_permanent_user(garage.id, "New User")
      assert perm_user.name == "New User"
      assert perm_user.rent_paid_until
    end
  end

  describe "balanced spot assignment" do
    setup do
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Test Garage"})

      level1 = Repo.insert!(%Level{number: 1, garage_id: garage.id})
      level2 = Repo.insert!(%Level{number: 2, garage_id: garage.id})

      Enum.each(1..3, fn n ->
        Repo.insert!(%ParkingSpot{number: n, level_id: level1.id})
      end)

      Enum.each(1..3, fn n ->
        Repo.insert!(%ParkingSpot{number: n, level_id: level2.id})
      end)

      pricing = insert_time_based_pricing(garage.id)

      %{garage: garage, level1: level1, level2: level2, pricing: pricing}
    end

    test "first two tickets land on different levels", %{
      garage: garage,
      pricing: pricing
    } do
      {:ok, t1} = ParkingSystem.create_ticket(garage.id, pricing.id)
      {:ok, t2} = ParkingSystem.create_ticket(garage.id, pricing.id)

      spot1 = Repo.get!(ParkingSpot, t1.spot_id)
      spot2 = Repo.get!(ParkingSpot, t2.spot_id)

      assert spot1.level_id != spot2.level_id,
             "Expected tickets to be assigned to different levels, both ended up on level_id=#{spot1.level_id}"
    end

    test "spots are spread across levels rather than stacking on one", %{
      garage: garage,
      level1: level1,
      level2: level2,
      pricing: pricing
    } do
      tickets =
        Enum.map(1..4, fn _ ->
          {:ok, t} = ParkingSystem.create_ticket(garage.id, pricing.id)
          t
        end)

      level_ids =
        tickets
        |> Enum.map(fn t -> Repo.get!(ParkingSpot, t.spot_id).level_id end)

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

      # Level 1: 3 spots, 2 reserved for permanent users (1 guest spot free)
      [l1s1, l1s2, _l1s3] =
        Enum.map(1..3, fn n ->
          Repo.insert!(%ParkingSpot{number: n, level_id: level1.id})
        end)

      # Level 2: 3 spots, none reserved (3 guest spots free)
      Enum.each(1..3, fn n ->
        Repo.insert!(%ParkingSpot{number: n, level_id: level2.id})
      end)

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
      {:ok, ticket} = ParkingSystem.create_ticket(garage.id, pricing.id)
      spot = Repo.get!(ParkingSpot, ticket.spot_id)

      assert spot.level_id == level2.id,
             "Expected first guest to be assigned to level2 (no reservations), got level_id=#{spot.level_id}"
    end
  end

  describe "garage statistics" do
    setup do
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Test Garage"})

      level = Repo.insert!(%Level{number: 1, garage_id: garage.id})
      pricing = insert_time_based_pricing(garage.id)

      spots =
        Enum.map(1..5, fn n ->
          Repo.insert!(%ParkingSpot{number: n, level_id: level.id})
        end)

      # Occupy 2 spots via active tickets
      Enum.each(Enum.take(spots, 2), fn spot ->
        Repo.insert!(%Ticket{
          entry_time: DateTime.utc_now() |> DateTime.truncate(:second),
          spot_id: spot.id,
          pricing_id: pricing.id
        })
      end)

      %{garage: garage, spots: spots}
    end

    test "get garage stats returns correct statistics", %{garage: garage} do
      stats = ParkingSystem.get_garage_stats(garage.id)

      assert stats.total_spots == 5
      assert stats.occupied_spots == 2
      assert stats.available_spots == 3
      assert stats.occupancy_rate == 40.0
    end

    test "guest parking status shows correct availability", %{garage: garage} do
      status = ParkingSystem.guest_parking_status(garage.id)

      assert status.total_spots == 5
      assert status.available_spots == 3
      assert status.occupied_spots == 2
      assert status.occupancy_rate == 40.0
    end
  end
end
