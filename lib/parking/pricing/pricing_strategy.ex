# lib/parking/pricing/pricing_strategy.ex
defmodule Parking.Pricing.PricingStrategy do
  @callback calculate(struct(), map()) :: float()

  def calculate(%module{} = strategy, ticket) do
    module.calculate(strategy, ticket)
  end
end
