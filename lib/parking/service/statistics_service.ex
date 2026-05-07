# lib/parking/services/statistics_service.ex
defmodule Parking.Services.StatisticsService do
  import Ecto.Query
  alias Parking.Repo
  alias Parking.Payment
  alias Parking.Ticket

  def calculate_revenue_by_period(start_date, end_date, garage_id, category \\ nil) do
    # Convert dates to start/end of day datetimes
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    end_datetime = DateTime.new!(end_date, ~T[23:59:59])

    query =
      from(p in Payment,
        join: t in Ticket,
        on: p.ticket_id == t.id,
        join: ps in assoc(t, :spot),
        join: l in assoc(ps, :level),
        where:
          p.timestamp >= ^start_datetime and p.timestamp <= ^end_datetime and
            l.garage_id == ^garage_id,
        select: %{
          amount: p.amount,
          category:
            fragment(
              "CASE WHEN ? IS NOT NULL THEN 'permanent' ELSE 'guest' END",
              t.permanent_user_id
            )
        }
      )

    case category do
      "guest" ->
        query |> where([p, t], is_nil(t.permanent_user_id))

      "permanent" ->
        query |> where([p, t], not is_nil(t.permanent_user_id))

      nil ->
        query
    end
    |> Repo.all()
    |> Enum.reduce(%{guest: 0.0, permanent: 0.0, total: 0.0}, fn %{amount: amount, category: cat},
                                                                 acc ->
      decimal_amount = Decimal.to_float(amount)

      Map.update(acc, String.to_existing_atom(cat), decimal_amount, &(&1 + decimal_amount))
      |> Map.update(:total, decimal_amount, &(&1 + decimal_amount))
    end)
  end

  def calculate_monthly_revenue(year, month, garage_id, category \\ nil) do
    start_date = Date.new!(year, month, 1)
    end_date = Date.add(start_date, Date.days_in_month(start_date) - 1)
    calculate_revenue_by_period(start_date, end_date, garage_id, category)
  end

  def calculate_yearly_revenue(year, garage_id, category \\ nil) do
    start_date = Date.new!(year, 1, 1)
    end_date = Date.new!(year, 12, 31)
    calculate_revenue_by_period(start_date, end_date, garage_id, category)
  end

end
