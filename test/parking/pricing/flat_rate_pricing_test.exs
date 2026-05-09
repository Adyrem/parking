defmodule Parking.Pricing.FlatRatePricingTest do
  use ExUnit.Case, async: true

  alias Parking.Pricing.FlatRatePricing

  describe "calculate/2" do
    test "charges one day for a sub-24h stay" do
      strategy = %FlatRatePricing{daily_rate: 20.0}
      ticket = %{entry_time: ~U[2026-04-09 10:00:00Z], exit_time: ~U[2026-04-09 18:00:00Z]}
      assert FlatRatePricing.calculate(strategy, ticket) == 20.0
    end

    test "charges two days for a stay just over 24h" do
      strategy = %FlatRatePricing{daily_rate: 20.0}
      ticket = %{entry_time: ~U[2026-04-09 10:00:00Z], exit_time: ~U[2026-04-10 10:00:01Z]}
      assert FlatRatePricing.calculate(strategy, ticket) == 40.0
    end

    test "charges exactly one day for a stay of exactly 24h" do
      strategy = %FlatRatePricing{daily_rate: 20.0}
      ticket = %{entry_time: ~U[2026-04-09 10:00:00Z], exit_time: ~U[2026-04-10 10:00:00Z]}
      assert FlatRatePricing.calculate(strategy, ticket) == 20.0
    end

    test "charges three days for a multi-day stay" do
      strategy = %FlatRatePricing{daily_rate: 15.0}
      ticket = %{entry_time: ~U[2026-04-09 08:00:00Z], exit_time: ~U[2026-04-11 20:00:00Z]}
      assert FlatRatePricing.calculate(strategy, ticket) == 45.0
    end
  end
end
