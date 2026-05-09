# lib/parking_web/live/stats_live.ex
defmodule ParkingWeb.StatsLive do
  use ParkingWeb, :live_view

  import Ecto.Query
  alias Parking.Repo
  alias Parking.ParkingGarage
  alias Parking.GarageStats
  alias Parking.Pricing.Calculator
  alias Parking.Services.StatisticsService
  alias Parking.Pricing
  alias Parking.Pricing.MonthlyRentConfig
  alias Parking.Pricing.DailyRateConfig

  def mount(params, _session, socket) do
    # Get garage_id from params or default to first garage
    garage_id = params["garage_id"] || get_default_garage_id()
    garage_id = if is_binary(garage_id), do: String.to_integer(garage_id), else: garage_id

    case Repo.get(ParkingGarage, garage_id) do
      nil ->
        # Garage not found, redirect to default garage
        default_garage_id = get_default_garage_id()
        {:ok, push_navigate(socket, to: ~p"/stats?garage_id=#{default_garage_id}")}

      garage ->
        {:ok,
         socket
         |> assign(garages: Repo.all(ParkingGarage), page_title: "Parkstatistiken")
         |> assign_stats(garage)}
    end
  end

  defp get_default_garage_id do
    case Repo.one(from g in ParkingGarage, order_by: [asc: g.id], limit: 1) do
      nil -> nil
      garage -> garage.id
    end
  end

  def handle_event("select_garage", %{"garage_id" => garage_id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/stats?garage_id=#{garage_id}")}
  end

  def handle_event("close_dropdowns", _params, socket) do
    # This event can be used if needed for programmatic closing
    {:noreply, socket}
  end

  def handle_event("copy_uuid", %{"uuid" => uuid}, socket) do
    {:noreply, push_event(socket, "copy-to-clipboard", %{uuid: uuid})}
  end

  def handle_params(%{"garage_id" => garage_id}, _uri, socket) do
    garage_id = String.to_integer(garage_id)

    case Repo.get(ParkingGarage, garage_id) do
      nil ->
        default_garage_id = get_default_garage_id()
        {:noreply, push_navigate(socket, to: ~p"/stats?garage_id=#{default_garage_id}")}

      garage ->
        {:noreply, assign_stats(socket, garage)}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp assign_stats(socket, garage) do
    current_date = Date.utc_today()

    pricing = Calculator.get_garage_pricing(garage.id)

    monthly_rent_rate =
      Repo.one(
        from p in Pricing,
          join: c in MonthlyRentConfig,
          on: c.pricing_id == p.id,
          where: p.garage_id == ^garage.id and p.type == "monthly_rent",
          select: c.monthly_rent,
          limit: 1
      )

    daily_rate =
      Repo.one(
        from p in Pricing,
          join: c in DailyRateConfig,
          on: c.pricing_id == p.id,
          where: p.garage_id == ^garage.id and p.type == "daily_rate",
          select: c.daily_rate,
          limit: 1
      )

    weekday_slots =
      if pricing, do: Enum.filter(pricing.time_slots, &(&1.slot_type == "weekday")), else: []

    weekend_slots =
      if pricing, do: Enum.filter(pricing.time_slots, &(&1.slot_type == "weekend")), else: []

    assign(socket,
      garage: garage,
      garage_id: garage.id,
      stats: GarageStats.get_garage_stats(garage.id),
      pricing: pricing,
      weekday_slots: weekday_slots,
      weekend_slots: weekend_slots,
      daily_rate: daily_rate,
      monthly_rent_rate: monthly_rent_rate,
      monthly_revenue:
        StatisticsService.calculate_monthly_revenue(
          current_date.year,
          current_date.month,
          garage.id
        ),
      yearly_revenue: StatisticsService.calculate_yearly_revenue(current_date.year, garage.id)
    )
  end

  def format_chf(amount) when is_float(amount) do
    :erlang.float_to_binary(amount, decimals: 2)
  end

  def format_chf(amount) do
    format_chf(amount * 1.0)
  end

  def current_ticket_fee(nil), do: nil
  def current_ticket_fee(%{permanent_user_id: id}) when not is_nil(id), do: nil

  def current_ticket_fee(ticket) do
    Calculator.calculate_fee(ticket)
  end
end
