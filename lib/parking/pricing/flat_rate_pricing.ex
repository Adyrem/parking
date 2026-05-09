# lib/parking/pricing/flat_rate_pricing.ex
defmodule Parking.Pricing.FlatRatePricing do
  @behaviour Parking.Pricing.PricingStrategy

  defstruct daily_rate: nil

  def calculate(%__MODULE__{daily_rate: rate}, ticket) do
    end_time = ticket.exit_time || DateTime.utc_now()
    seconds = DateTime.diff(end_time, ticket.entry_time, :second)
    days = Float.ceil(seconds / (24 * 3600))
    Float.round(days * rate, 2)
  end
end
