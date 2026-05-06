# lib/parking/pricing/time_based_pricing.ex
defmodule Parking.Pricing.TimeBasedPricing do
  @behaviour Parking.Pricing.PricingStrategy

  defstruct time_slots: [],
            weekend_time_slots: nil,
            holiday_time_slots: nil,
            holidays: [],
            daily_rate: nil,
            default_rate_per_hour: nil

  def calculate(%__MODULE__{} = strategy, ticket) do
    end_time = ticket.exit_time || NaiveDateTime.utc_now()
    duration = NaiveDateTime.diff(end_time, ticket.entry_time, :second)

    if duration > 24 * 3600 do
      days = Float.ceil(duration / (24 * 3600))
      Float.round(days * strategy.daily_rate, 2)
    else
      start = floor_to_quarter(ticket.entry_time)
      calculate_quarters(start, end_time, strategy, 0.0)
    end
  end

  defp calculate_quarters(start_time, end_time, strategy, total) do
    if NaiveDateTime.compare(start_time, end_time) == :lt do
      rate = rate_for(start_time, strategy)

      calculate_quarters(
        NaiveDateTime.add(start_time, 15 * 60, :second),
        end_time,
        strategy,
        total + rate * 0.25
      )
    else
      Float.round(total, 2)
    end
  end

  defp floor_to_quarter(datetime) do
    time = NaiveDateTime.to_time(datetime)
    minutes = time.hour * 60 + time.minute
    quarter_start = div(minutes, 15) * 15

    {:ok, time} = Time.new(div(quarter_start, 60), rem(quarter_start, 60), 0)
    NaiveDateTime.new!(NaiveDateTime.to_date(datetime), time)
  end

  defp rate_for(datetime, strategy) do
    datetime = DateTime.from_naive!(datetime, "Etc/UTC")
    date = DateTime.to_date(datetime)
    minutes = time_to_minutes(DateTime.to_time(datetime))

    cond do
      holiday?(date, strategy) and strategy.holiday_time_slots ->
        rate_for_slot_list(minutes, strategy.holiday_time_slots, strategy.default_rate_per_hour)

      weekend?(date) and strategy.weekend_time_slots ->
        rate_for_slot_list(minutes, strategy.weekend_time_slots, strategy.default_rate_per_hour)

      strategy.time_slots ->
        rate_for_slot_list(minutes, strategy.time_slots, strategy.default_rate_per_hour)

      true ->
        strategy.default_rate_per_hour
    end
  end

  defp holiday?(date, strategy) do
    Enum.any?(strategy.holidays || [], fn holiday ->
      case Date.from_iso8601(holiday) do
        {:ok, holiday_date} -> holiday_date == date
        _ -> false
      end
    end)
  end

  defp weekend?(date) do
    day = Date.day_of_week(date)
    day in [6, 7]
  end

  defp rate_for_slot_list(minutes, slots, default_rate) do
    slots
    |> Enum.find_value(default_rate, fn slot ->
      from = parse_time_slot(slot["from"])
      to = parse_time_slot(slot["to"])

      if slot_matches?(minutes, from, to) do
        slot["rate_per_hour"] || default_rate
      else
        false
      end
    end)
  end

  defp parse_time_slot(nil), do: 0

  defp parse_time_slot("24:00"), do: 24 * 60

  defp parse_time_slot(time_string) do
    case String.split(time_string, ":") do
      [h, m | _] ->
        {hours, _} = Integer.parse(h)
        {minutes, _} = Integer.parse(m)
        hours * 60 + minutes

      _ ->
        0
    end
  end

  defp slot_matches?(minutes, from, to) when from < to do
    minutes >= from and minutes < to
  end

  defp slot_matches?(minutes, from, to) when from >= to do
    minutes >= from or minutes < to
  end

  defp time_to_minutes(time) do
    time.hour * 60 + time.minute
  end
end
