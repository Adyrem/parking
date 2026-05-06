# lib/parking/pricing/flat_rate_pricing.ex
defmodule Parking.Pricing.FlatRatePricing do
  @behaviour Parking.Pricing.PricingStrategy

  defstruct daily_rate: nil

  def calculate(%__MODULE__{daily_rate: rate}, _ticket) do
    rate
  end
end
