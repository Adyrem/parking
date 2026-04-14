defmodule Parking.Pricing.TimeBasedPricingTest do
  use Parking.DataCase

  alias Parking.Pricing.TimeBasedPricing

  describe "calculate/2" do
    test "calculates basic hourly rate" do
      config = %{
        "base_rate" => 2.0,
        "hourly_rate" => 3.0,
        "daily_rate" => 20.0,
        "time_slots" => [],
        "weekend_multiplier" => 1.0,
        "holiday_multiplier" => 1.0,
        "quarter_hour_billing" => false
      }

      strategy = %TimeBasedPricing{
        time_slots: config["time_slots"],
        weekend_time_slots: nil,
        holiday_time_slots: nil,
        holidays: [],
        daily_rate: config["daily_rate"],
        default_rate_per_hour: config["hourly_rate"]
      }

      # 2 hours parking
      ticket = %{entry_time: ~U[2026-04-10 10:00:00Z], exit_time: ~U[2026-04-10 12:00:00Z]}

      amount = TimeBasedPricing.calculate(strategy, ticket)
      # base_rate + 2 * hourly_rate = 2 + 6 = 8
      # 2 * 3.0
      assert amount == 6.0
    end

    test "applies time slot rates" do
      config = %{
        "base_rate" => 0.0,
        "hourly_rate" => 1.0,
        "daily_rate" => 20.0,
        "time_slots" => [
          %{"from" => "06:00", "to" => "18:00", "rate_per_hour" => 3.0},
          %{"from" => "18:00", "to" => "22:00", "rate_per_hour" => 4.0},
          %{"from" => "22:00", "to" => "23:59", "rate_per_hour" => 2.0}
        ],
        "weekend_multiplier" => 1.0,
        "holiday_multiplier" => 1.0,
        "quarter_hour_billing" => false
      }

      strategy = %TimeBasedPricing{
        time_slots: config["time_slots"],
        weekend_time_slots: nil,
        holiday_time_slots: nil,
        holidays: [],
        daily_rate: config["daily_rate"],
        default_rate_per_hour: config["hourly_rate"]
      }

      # 2 hours during day slot (3.0/hour)
      ticket = %{entry_time: ~U[2026-04-10 10:00:00Z], exit_time: ~U[2026-04-10 12:00:00Z]}

      amount = TimeBasedPricing.calculate(strategy, ticket)
      # 2 * 3.0
      assert amount == 6.0
    end

    test "applies weekend rates" do
      config = %{
        "base_rate" => 2.0,
        "hourly_rate" => 3.0,
        "daily_rate" => 20.0,
        "time_slots" => [],
        "weekend_multiplier" => 1.5,
        "holiday_multiplier" => 1.0,
        "quarter_hour_billing" => false
      }

      strategy = %TimeBasedPricing{
        time_slots: config["time_slots"],
        weekend_time_slots: [%{"from" => "00:00", "to" => "23:59", "rate_per_hour" => 4.5}],
        holiday_time_slots: nil,
        holidays: [],
        daily_rate: config["daily_rate"],
        default_rate_per_hour: config["hourly_rate"]
      }

      # Weekend (Saturday)
      ticket = %{entry_time: ~U[2026-04-12 10:00:00Z], exit_time: ~U[2026-04-12 12:00:00Z]}

      amount = TimeBasedPricing.calculate(strategy, ticket)
      # 2 * 4.5
      assert amount == 9.0
    end

    test "applies quarter hour billing" do
      config = %{
        "base_rate" => 0.0,
        # 1 CHF per 15 minutes
        "hourly_rate" => 4.0,
        "daily_rate" => 20.0,
        "time_slots" => [],
        "weekend_multiplier" => 1.0,
        "holiday_multiplier" => 1.0,
        "quarter_hour_billing" => true
      }

      strategy = %TimeBasedPricing{
        time_slots: config["time_slots"],
        weekend_time_slots: nil,
        holiday_time_slots: nil,
        holidays: [],
        daily_rate: config["daily_rate"],
        default_rate_per_hour: config["hourly_rate"]
      }

      # 45 minutes = 3 quarter hours
      ticket = %{entry_time: ~U[2026-04-10 10:00:00Z], exit_time: ~U[2026-04-10 10:45:00Z]}

      amount = TimeBasedPricing.calculate(strategy, ticket)
      # 3 * 1.0 (4.0/4)
      assert amount == 3.0
    end

    test "applies daily flat rate after 24 hours" do
      config = %{
        "base_rate" => 2.0,
        "hourly_rate" => 3.0,
        "daily_rate" => 20.0,
        "time_slots" => [],
        "weekend_multiplier" => 1.0,
        "holiday_multiplier" => 1.0,
        "quarter_hour_billing" => false
      }

      strategy = %TimeBasedPricing{
        time_slots: config["time_slots"],
        weekend_time_slots: nil,
        holiday_time_slots: nil,
        holidays: [],
        daily_rate: config["daily_rate"],
        default_rate_per_hour: config["hourly_rate"]
      }

      # 25 hours parking
      ticket = %{entry_time: ~U[2026-04-10 10:00:00Z], exit_time: ~U[2026-04-11 11:00:00Z]}

      amount = TimeBasedPricing.calculate(strategy, ticket)
      # 2 * 20.0 (daily rate)
      assert amount == 40.0
    end

    test "handles minimum parking time" do
      config = %{
        "base_rate" => 2.0,
        "hourly_rate" => 3.0,
        "daily_rate" => 20.0,
        "time_slots" => [],
        "weekend_multiplier" => 1.0,
        "holiday_multiplier" => 1.0,
        "quarter_hour_billing" => false
      }

      strategy = %TimeBasedPricing{
        time_slots: config["time_slots"],
        weekend_time_slots: nil,
        holiday_time_slots: nil,
        holidays: [],
        daily_rate: config["daily_rate"],
        default_rate_per_hour: config["hourly_rate"]
      }

      # 5 minutes parking (should charge for 1 quarter hour)
      ticket = %{entry_time: ~U[2026-04-10 10:00:00Z], exit_time: ~U[2026-04-10 10:05:00Z]}

      amount = TimeBasedPricing.calculate(strategy, ticket)
      # 1 * (3.0/4)
      assert amount == 0.75
    end
  end
end
