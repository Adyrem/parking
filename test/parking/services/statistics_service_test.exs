defmodule Parking.Services.StatisticsServiceTest do
  use Parking.DataCase

  alias Parking.Services.StatisticsService
  alias Parking.Repo
  alias Parking.ParkingGarage
  alias Parking.Pricing
  alias Parking.Pricing.TimeBasedConfig
  alias Parking.Ticket
  alias Parking.Payment
  alias Parking.Level
  alias Parking.ParkingSpot

  describe "revenue calculations" do
    setup do
      # Create test garage
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Test Garage"})

      # Create pricing
      pricing = Repo.insert!(%Pricing{garage_id: garage.id, type: "time_based"})
      Repo.insert!(%TimeBasedConfig{pricing_id: pricing.id, rate_per_hour: 2.0})

      # Create level and spots
      level = Repo.insert!(%Level{number: 1, garage_id: garage.id})
      spot = Repo.insert!(%ParkingSpot{number: 1, level_id: level.id})

      %{garage: garage, pricing: pricing, spot: spot}
    end

    test "calculate monthly revenue", %{garage: garage, pricing: pricing, spot: spot} do
      # Create tickets and payments for current month
      current_date = Date.utc_today()
      entry_time = DateTime.new!(current_date, ~T[10:00:00])

      # Create ticket
      {:ok, ticket} =
        Repo.insert(%Ticket{
          entry_time: entry_time,
          exit_time: DateTime.add(entry_time, 2, :hour),
          spot_id: spot.id,
          pricing_id: pricing.id
        })

      # Create payment
      Repo.insert!(%Payment{
        amount: Decimal.new("8.0"),
        ticket_id: ticket.id
      })

      # Calculate revenue
      revenue =
        StatisticsService.calculate_monthly_revenue(
          current_date.year,
          current_date.month,
          garage.id
        )

      assert revenue.total == 8.0
      assert revenue.guest == 8.0
      assert revenue.permanent == 0.0
    end

    test "calculate yearly revenue", %{garage: garage, pricing: pricing, spot: spot} do
      # Create tickets and payments for current year
      current_date = Date.utc_today()
      entry_time = DateTime.new!(Date.new!(current_date.year, 1, 15), ~T[10:00:00])

      # Create ticket
      {:ok, ticket} =
        Repo.insert(%Ticket{
          entry_time: entry_time,
          exit_time: DateTime.add(entry_time, 1, :hour),
          spot_id: spot.id,
          pricing_id: pricing.id
        })

      # Create payment
      Repo.insert!(%Payment{
        amount: Decimal.new("5.0"),
        ticket_id: ticket.id
      })

      # Calculate revenue
      revenue = StatisticsService.calculate_yearly_revenue(current_date.year, garage.id)

      assert revenue.total == 5.0
      assert revenue.guest == 5.0
      assert revenue.permanent == 0.0
    end

    test "calculate revenue by period", %{garage: garage, pricing: pricing, spot: spot} do
      start_date = ~D[2026-04-01]
      end_date = ~D[2026-04-30]

      entry_time = DateTime.new!(~D[2026-04-10], ~T[10:00:00])

      # Create ticket
      {:ok, ticket} =
        Repo.insert(%Ticket{
          entry_time: entry_time,
          exit_time: DateTime.add(entry_time, 3, :hour),
          spot_id: spot.id,
          pricing_id: pricing.id
        })

      # Create payment
      Repo.insert!(%Payment{
        amount: Decimal.new("11.0"),
        ticket_id: ticket.id
      })

      # Calculate revenue
      revenue = StatisticsService.calculate_revenue_by_period(start_date, end_date, garage.id)

      assert revenue.total == 11.0
      assert revenue.guest == 11.0
      assert revenue.permanent == 0.0
    end

    test "filters by category", %{garage: garage, pricing: pricing, spot: spot} do
      current_date = Date.utc_today()
      entry_time = DateTime.new!(current_date, ~T[10:00:00])

      # Create guest ticket
      {:ok, guest_ticket} =
        Repo.insert(%Ticket{
          entry_time: entry_time,
          exit_time: DateTime.add(entry_time, 1, :hour),
          spot_id: spot.id,
          pricing_id: pricing.id
        })

      Repo.insert!(%Payment{
        amount: Decimal.new("5.0"),
        ticket_id: guest_ticket.id
      })

      # Create permanent user ticket
      {:ok, user} = Repo.insert(%Parking.Users.User{type: "permanent"})

      {:ok, perm_user} =
        Repo.insert(%Parking.Users.PermanentUser{
          id: user.id,
          name: "Test User",
          access_code: "123456",
          is_blocked: false
        })

      {:ok, permanent_ticket} =
        Repo.insert(%Ticket{
          entry_time: entry_time,
          exit_time: DateTime.add(entry_time, 2, :hour),
          spot_id: spot.id,
          pricing_id: nil,
          permanent_user_id: perm_user.id
        })

      Repo.insert!(%Payment{
        amount: Decimal.new("10.0"),
        ticket_id: permanent_ticket.id
      })

      # Test guest-only revenue
      guest_revenue =
        StatisticsService.calculate_monthly_revenue(
          current_date.year,
          current_date.month,
          garage.id,
          "guest"
        )

      assert guest_revenue.total == 5.0
      assert guest_revenue.guest == 5.0
      assert guest_revenue.permanent == 0.0

      # Test permanent-only revenue
      perm_revenue =
        StatisticsService.calculate_monthly_revenue(
          current_date.year,
          current_date.month,
          garage.id,
          "permanent"
        )

      assert perm_revenue.total == 10.0
      assert perm_revenue.guest == 0.0
      assert perm_revenue.permanent == 10.0

      # Test total revenue
      total_revenue =
        StatisticsService.calculate_monthly_revenue(
          current_date.year,
          current_date.month,
          garage.id
        )

      assert total_revenue.total == 15.0
      assert total_revenue.guest == 5.0
      assert total_revenue.permanent == 10.0
    end
  end
end
