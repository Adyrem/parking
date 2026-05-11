defmodule Parking.Pricing.Calculator do
  import Ecto.Query
  alias Parking.Repo
  alias Parking.Pricing.TimeBasedPricing
  alias Parking.Pricing.PricingStrategy
  alias Parking.Pricing.DailyRateConfig

  @doc "Calculate fee for a ticket based on its pricing strategy"
  def calculate_fee(ticket) do
    ticket =
      Repo.preload(ticket,
        pricing: [:time_based_config, :daily_rate_config, :time_slots, :holidays],
        permanent_user: []
      )

    if ticket.permanent_user_id do
      0.0
    else
      build_strategy_and_calculate(ticket.pricing, ticket)
    end
  end

  defp build_strategy_and_calculate(nil, _ticket), do: 0.0

  defp build_strategy_and_calculate(pricing, ticket) do
    case pricing.type do
      "time_based" ->
        case pricing.time_based_config do
          nil ->
            0.0

          config ->
            daily_rate = get_garage_daily_rate(pricing.garage_id)

            strategy = %TimeBasedPricing{
              time_slots: build_slots(pricing.time_slots, "weekday"),
              weekend_time_slots: build_slots(pricing.time_slots, "weekend"),
              holiday_time_slots: build_slots(pricing.time_slots, "holiday"),
              holidays: Enum.map(pricing.holidays, & &1.date),
              daily_rate: daily_rate,
              default_rate_per_hour: config.rate_per_hour
            }

            PricingStrategy.calculate(strategy, ticket)
        end

      "daily_rate" ->
        case pricing.daily_rate_config do
          nil ->
            0.0

          config ->
            strategy = %Parking.Pricing.FlatRatePricing{daily_rate: config.daily_rate}
            PricingStrategy.calculate(strategy, ticket)
        end

      _ ->
        0.0
    end
  end

  defp build_slots(time_slots, slot_type) do
    result = Enum.filter(time_slots, &(&1.slot_type == slot_type))
    if result == [], do: nil, else: result
  end

  defp get_garage_daily_rate(garage_id) do
    Repo.one(
      from p in Parking.Pricing,
        join: c in DailyRateConfig,
        on: c.pricing_id == p.id,
        where: p.garage_id == ^garage_id and p.type == "daily_rate",
        select: c.daily_rate,
        limit: 1
    )
  end

  @doc "Get the active time-based pricing configuration for a garage"
  def get_garage_pricing(garage_id) do
    Repo.one(
      from p in Parking.Pricing,
        where: p.garage_id == ^garage_id and p.type == "time_based",
        preload: [:time_based_config, :time_slots, :holidays],
        order_by: [asc: p.id],
        limit: 1
    )
  end
end
