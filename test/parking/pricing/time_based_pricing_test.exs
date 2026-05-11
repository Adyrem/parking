defmodule Parking.Pricing.TimeBasedPricingTest do
  use Parking.DataCase

  alias Parking.Pricing.TimeBasedPricing

  describe "calculate/2" do
    test "calculates basic hourly rate" do
      strategy = %TimeBasedPricing{
        time_slots: [],
        weekend_time_slots: nil,
        holiday_time_slots: nil,
        holidays: [],
        daily_rate: 35.0,
        default_rate_per_hour: 3.0
      }

      # 2 hours parking: 8 quarters × (3.0/4)
      ticket = %{entry_time: ~U[2026-04-10 10:00:00Z], exit_time: ~U[2026-04-10 12:00:00Z]}

      assert TimeBasedPricing.calculate(strategy, ticket) == 6.0
    end

    test "applies time slot rates" do
      strategy = %TimeBasedPricing{
        time_slots: [
          %{from_time: "06:00", to_time: "18:00", rate_per_hour: 3.0},
          %{from_time: "18:00", to_time: "22:00", rate_per_hour: 4.0},
          %{from_time: "22:00", to_time: "24:00", rate_per_hour: 2.0}
        ],
        weekend_time_slots: nil,
        holiday_time_slots: nil,
        holidays: [],
        daily_rate: 35.0,
        default_rate_per_hour: 1.0
      }

      # 2 hours during day slot (3.0/hour)
      ticket = %{entry_time: ~U[2026-04-10 10:00:00Z], exit_time: ~U[2026-04-10 12:00:00Z]}

      # 2 * 3.0
      assert TimeBasedPricing.calculate(strategy, ticket) == 6.0
    end

    test "applies weekend rates" do
      strategy = %TimeBasedPricing{
        time_slots: [],
        weekend_time_slots: [%{from_time: "00:00", to_time: "24:00", rate_per_hour: 4.5}],
        holiday_time_slots: nil,
        holidays: [],
        daily_rate: 35.0,
        default_rate_per_hour: 3.0
      }

      # Weekend (Saturday 2026-04-12)
      ticket = %{entry_time: ~U[2026-04-12 10:00:00Z], exit_time: ~U[2026-04-12 12:00:00Z]}

      # 2 * 4.5
      assert TimeBasedPricing.calculate(strategy, ticket) == 9.0
    end

    test "applies quarter hour billing" do
      strategy = %TimeBasedPricing{
        time_slots: [],
        weekend_time_slots: nil,
        holiday_time_slots: nil,
        holidays: [],
        daily_rate: 35.0,
        # 1 CHF per 15 minutes
        default_rate_per_hour: 4.0
      }

      # 45 minutes = 3 quarter hours
      ticket = %{entry_time: ~U[2026-04-10 10:00:00Z], exit_time: ~U[2026-04-10 10:45:00Z]}

      # 3 * 1.0 (4.0/4)
      assert TimeBasedPricing.calculate(strategy, ticket) == 3.0
    end

    test "applies daily flat rate after 24 hours" do
      strategy = %TimeBasedPricing{
        time_slots: [],
        weekend_time_slots: nil,
        holiday_time_slots: nil,
        holidays: [],
        daily_rate: 35.0,
        default_rate_per_hour: 3.0
      }

      # 25 hours parking → 2 started days × CHF 35.00 (spec §5.1.3)
      ticket = %{entry_time: ~U[2026-04-10 10:00:00Z], exit_time: ~U[2026-04-11 11:00:00Z]}

      # Float.ceil(25/24) = 2 → 2 * 35.0
      assert TimeBasedPricing.calculate(strategy, ticket) == 70.0
    end

    test "handles minimum parking time" do
      strategy = %TimeBasedPricing{
        time_slots: [],
        weekend_time_slots: nil,
        holiday_time_slots: nil,
        holidays: [],
        daily_rate: 35.0,
        default_rate_per_hour: 3.0
      }

      # 5 minutes parking (should charge for 1 quarter hour)
      ticket = %{entry_time: ~U[2026-04-10 10:00:00Z], exit_time: ~U[2026-04-10 10:05:00Z]}

      # 1 * (3.0/4)
      assert TimeBasedPricing.calculate(strategy, ticket) == 0.75
    end
  end

  describe "spec-compliant tariff verification" do
    setup do
      strategy = %TimeBasedPricing{
        time_slots: [
          %{from_time: "00:00", to_time: "06:00", rate_per_hour: 2.50},
          %{from_time: "06:00", to_time: "09:00", rate_per_hour: 2.80},
          %{from_time: "09:00", to_time: "18:00", rate_per_hour: 3.60},
          %{from_time: "18:00", to_time: "21:00", rate_per_hour: 2.80},
          %{from_time: "21:00", to_time: "24:00", rate_per_hour: 2.40}
        ],
        weekend_time_slots: [
          %{from_time: "00:00", to_time: "09:00", rate_per_hour: 2.40},
          %{from_time: "09:00", to_time: "18:00", rate_per_hour: 3.20},
          %{from_time: "18:00", to_time: "24:00", rate_per_hour: 2.40}
        ],
        holiday_time_slots: [
          %{from_time: "00:00", to_time: "09:00", rate_per_hour: 2.40},
          %{from_time: "09:00", to_time: "18:00", rate_per_hour: 3.20},
          %{from_time: "18:00", to_time: "24:00", rate_per_hour: 2.40}
        ],
        holidays: [~D[2026-01-01], ~D[2026-12-25]],
        daily_rate: 35.0,
        default_rate_per_hour: 2.50
      }

      %{strategy: strategy}
    end

    test "weekday daytime slot (09:00–18:00) at CHF 3.60/h", %{strategy: strategy} do
      # Thursday 2026-04-09, 10:00–12:00 → 8 quarters in daytime slot
      ticket = %{entry_time: ~U[2026-04-09 10:00:00Z], exit_time: ~U[2026-04-09 12:00:00Z]}
      # 8 × (3.60/4) = 7.20
      assert TimeBasedPricing.calculate(strategy, ticket) == 7.20
    end

    test "rate changes correctly at slot boundary (cross-slot billing)", %{strategy: strategy} do
      # Thursday 2026-04-10, 17:50–18:10
      # floor_to_quarter(17:50) = 17:45 → rate 3.60 (daytime) → 0.90
      # quarter 18:00 → rate 2.80 (evening) → 0.70
      ticket = %{entry_time: ~U[2026-04-10 17:50:00Z], exit_time: ~U[2026-04-10 18:10:00Z]}
      assert TimeBasedPricing.calculate(strategy, ticket) == 1.60
    end

    test "exactly 24 hours uses hourly billing, not daily rate" do
      # duration == 86400 is NOT > 86400, so quarterly billing applies
      # Thursday 10:00 → Friday 10:00, no time slots → default_rate_per_hour
      strategy = %TimeBasedPricing{
        time_slots: [],
        weekend_time_slots: nil,
        holiday_time_slots: nil,
        holidays: [],
        daily_rate: 35.0,
        default_rate_per_hour: 3.0
      }

      ticket = %{entry_time: ~U[2026-04-09 10:00:00Z], exit_time: ~U[2026-04-10 10:00:00Z]}
      # 96 quarters × (3.0/4) = 72.0 — daily rate NOT triggered
      assert TimeBasedPricing.calculate(strategy, ticket) == 72.0
    end

    test "applies holiday rates instead of weekday rates on configured holiday", %{
      strategy: strategy
    } do
      # 2026-01-01 is New Year's Day (Thursday — would be weekday 3.60, but holiday overrides to 3.20)
      ticket = %{entry_time: ~U[2026-01-01 10:00:00Z], exit_time: ~U[2026-01-01 12:00:00Z]}
      # 8 quarters × (3.20/4) = 6.40
      assert TimeBasedPricing.calculate(strategy, ticket) == 6.40
    end
  end
end
