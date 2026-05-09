# lib/parking/parking_system.ex
defmodule Parking.ParkingSystem do
  import Ecto.Query
  alias Parking.Repo
  alias Parking.ParkingGarage
  alias Parking.Level
  alias Parking.ParkingSpot
  alias Parking.Ticket
  alias Parking.Payment
  alias Parking.Users.PermanentUser

  alias Parking.Pricing.TimeBasedPricing
  alias Parking.Pricing.PricingStrategy
  alias Parking.Pricing.MonthlyRentConfig
  alias Parking.Pricing.DailyRateConfig
  alias Parking.Services.PaymentService
  alias Parking.Services.AccountingService
  alias Parking.Users.User

  @doc "Create a new ticket, assign a parking spot, and persist to database"
  def create_ticket(garage_id, pricing_id) do
    Repo.transaction(fn ->
      spot =
        guest_spot_query(garage_id)
        |> limit(1)
        |> Repo.one()

      case spot do
        nil ->
          Repo.rollback(:no_available_spots)

        spot ->
          ticket_changeset =
            Ticket.changeset(%Ticket{}, %{
              "entry_time" => DateTime.truncate(DateTime.utc_now(), :second),
              "spot_id" => spot.id,
              "pricing_id" => pricing_id
            })

          with {:ok, ticket} <- Repo.insert(ticket_changeset) do
            Repo.preload(ticket, [:spot, :pricing])
          end
      end
    end)
  end

  defp guest_spot_query(garage_id) do
    # A spot is occupied if it has an active ticket (exit_time IS NULL).
    active_spot_ids = from(t in Ticket, where: is_nil(t.exit_time), select: t.spot_id)
    perm_spot_ids = from(p in PermanentUser, select: p.spot_id)

    level_occupancy =
      from(s in ParkingSpot,
        join: l in Level,
        on: s.level_id == l.id,
        where:
          l.garage_id == ^garage_id and
            (s.id in subquery(active_spot_ids) or s.id in subquery(perm_spot_ids)),
        group_by: l.id,
        select: %{level_id: l.id, occupied_count: count(s.id)}
      )

    from(s in ParkingSpot,
      join: l in Level,
      on: s.level_id == l.id,
      left_join: lo in subquery(level_occupancy),
      on: lo.level_id == l.id,
      where:
        l.garage_id == ^garage_id and
          s.id not in subquery(active_spot_ids) and
          s.id not in subquery(perm_spot_ids),
      order_by: [asc: coalesce(lo.occupied_count, 0), asc: s.id],
      select: s
    )
  end

  @doc "Get the guest parking status excluding permanent reserved spots"
  def guest_parking_status(garage_id) do
    perm_spot_ids = from(p in PermanentUser, select: p.spot_id)
    active_spot_ids = from(t in Ticket, where: is_nil(t.exit_time), select: t.spot_id)

    spots =
      from(s in ParkingSpot,
        join: l in Level,
        on: s.level_id == l.id,
        where:
          l.garage_id == ^garage_id and
            s.id not in subquery(perm_spot_ids),
        select: %{is_occupied: s.id in subquery(active_spot_ids)}
      )
      |> Repo.all()

    total_spots = length(spots)
    occupied_spots = Enum.count(spots, & &1.is_occupied)
    available_spots = total_spots - occupied_spots

    occupancy_rate =
      if(total_spots == 0, do: 0.0, else: Float.round(occupied_spots / total_spots * 100, 1))

    %{
      total_spots: total_spots,
      occupied_spots: occupied_spots,
      available_spots: available_spots,
      occupancy_rate: occupancy_rate
    }
  end

  @doc "Calculate fee for a ticket based on pricing strategy"
  def calculate_fee(ticket) do
    ticket =
      Repo.preload(ticket, [
        pricing: [:time_based_config, :daily_rate_config, :time_slots, :holidays],
        permanent_user: []
      ])

    if ticket.permanent_user_id do
      0.0
    else
      recreate_strategy_and_calculate(ticket.pricing, ticket)
    end
  end

  defp recreate_strategy_and_calculate(nil, _ticket), do: 0.0

  defp recreate_strategy_and_calculate(pricing, ticket) do
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
              holidays: Enum.map(pricing.holidays, &Date.to_iso8601(&1.date)),
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
    result =
      time_slots
      |> Enum.filter(&(&1.slot_type == slot_type))
      |> Enum.map(fn slot ->
        %{"from" => slot.from_time, "to" => slot.to_time, "rate_per_hour" => slot.rate_per_hour}
      end)

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

  @doc "Process payment for a ticket - creates a payment record"
  def process_payment(ticket) do
    Repo.transaction(fn ->
      amount = calculate_fee(ticket)

      case PaymentService.process(nil, amount) do
        {:ok, _} -> :ok
        {:error, reason} -> Repo.rollback(reason)
      end

      payment_changeset =
        Payment.changeset(%Payment{}, %{
          "amount" => Decimal.from_float(amount),
          "ticket_id" => ticket.id
        })

      with {:ok, _payment} <- Repo.insert(payment_changeset) do
        AccountingService.record_transaction(nil, amount)
        ticket
      end
    end)
  end

  @doc "Register vehicle exit - update exit time on the ticket"
  def register_exit(ticket) do
    Repo.transaction(fn ->
      ticket = Repo.preload(ticket, :spot)

      ticket_paid? = Repo.exists?(from p in Payment, where: p.ticket_id == ^ticket.id)

      cond do
        ticket.permanent_user_id == nil and not ticket_paid? ->
          Repo.rollback(:payment_required)

        true ->
          ticket_changeset =
            Ticket.changeset(ticket, %{exit_time: DateTime.truncate(DateTime.utc_now(), :second)})

          with {:ok, updated_ticket} <- Repo.update(ticket_changeset) do
            updated_ticket
          end
      end
    end)
  end

  @doc "Get garage with all preloaded data"
  def get_garage(garage_id) do
    from(g in ParkingGarage,
      where: g.id == ^garage_id,
      preload: [levels: [spots: :tickets]]
    )
    |> Repo.one()
  end

  @doc "List all permanent users with assigned spot and account metadata"
  def list_permanent_users do
    from(p in Parking.Users.PermanentUser,
      preload: [:spot, :user],
      order_by: [asc: p.id]
    )
    |> Repo.all()
  end

  @doc "List permanent users for a specific garage, with is_parked derived from active tickets"
  def list_permanent_users(garage_id) do
    users =
      from(p in Parking.Users.PermanentUser,
        join: s in ParkingSpot,
        on: p.spot_id == s.id,
        join: l in Level,
        on: s.level_id == l.id,
        where: l.garage_id == ^garage_id,
        preload: [:spot, :user],
        order_by: [asc: p.id]
      )
      |> Repo.all()

    parked_ids =
      from(t in Ticket,
        where: t.permanent_user_id in ^Enum.map(users, & &1.id) and is_nil(t.exit_time),
        select: t.permanent_user_id
      )
      |> Repo.all()
      |> MapSet.new()

    Enum.map(users, fn user -> %{user | is_parked: user.id in parked_ids} end)
  end

  @doc "Authenticate a permanent user by access code"
  def authenticate_permanent_user(code) when is_binary(code) do
    query =
      from(p in Parking.Users.PermanentUser,
        where: p.access_code == ^code,
        preload: [:spot, :user]
      )

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      perm_user ->
        perm_user = maybe_enforce_rent_block(perm_user)

        if perm_user.is_blocked do
          {:error, {:blocked, perm_user}}
        else
          {:ok, perm_user}
        end
    end
  end

  defp maybe_enforce_rent_block(%Parking.Users.PermanentUser{} = perm_user) do
    if Parking.Users.PermanentUser.rent_due?(perm_user) and not perm_user.is_blocked do
      perm_user
      |> Parking.Users.PermanentUser.changeset(%{is_blocked: true})
      |> Repo.update!()
    else
      perm_user
    end
  end

  @doc "Process monthly rent payment for a permanent user"
  def process_rent_payment(%PermanentUser{} = perm_user) do
    perm_user = Repo.preload(perm_user, spot: :level)
    garage_id = perm_user.spot.level.garage_id

    Repo.transaction(fn ->
      now = DateTime.truncate(DateTime.utc_now(), :second)
      paid_until = calculate_next_rent_paid_until(perm_user)
      monthly_rent = parse_monthly_rent(garage_id)

      ticket =
        Ticket.changeset(%Ticket{}, %{
          "entry_time" => now,
          "exit_time" => now,
          "spot_id" => perm_user.spot_id,
          "permanent_user_id" => perm_user.id
        })
        |> Repo.insert!()

      Payment.changeset(%Payment{}, %{
        "amount" => Decimal.from_float(monthly_rent),
        "ticket_id" => ticket.id
      })
      |> Repo.insert!()

      perm_user
      |> PermanentUser.changeset(%{
        is_blocked: false,
        rent_paid_until: paid_until,
        last_rent_payment_at: now
      })
      |> Repo.update!()
    end)
  end

  defp parse_monthly_rent(garage_id) do
    result =
      Repo.one(
        from p in Parking.Pricing,
          join: c in MonthlyRentConfig,
          on: c.pricing_id == p.id,
          where: p.garage_id == ^garage_id and p.type == "monthly_rent",
          select: c.monthly_rent,
          limit: 1
      )

    result || raise "monthly_rent not configured for garage #{garage_id}"
  end

  defp calculate_next_rent_paid_until(%Parking.Users.PermanentUser{rent_paid_until: nil}) do
    end_of_month(Date.utc_today())
  end

  defp calculate_next_rent_paid_until(%Parking.Users.PermanentUser{rent_paid_until: paid_until}) do
    today = Date.utc_today()
    current_month_start = %Date{year: today.year, month: today.month, day: 1}

    if Date.compare(paid_until, current_month_start) == :lt do
      end_of_month(today)
    else
      next_month_end(paid_until)
    end
  end

  defp next_month_end(%Date{year: year, month: 12, day: _day}) do
    end_of_month(%Date{year: year + 1, month: 1, day: 1})
  end

  defp next_month_end(%Date{year: year, month: month, day: _day}) do
    end_of_month(%Date{year: year, month: month + 1, day: 1})
  end

  defp end_of_month(%Date{year: year, month: month, day: _day}) do
    days = Date.days_in_month(%Date{year: year, month: month, day: 1})
    %Date{year: year, month: month, day: days}
  end

  @doc "Mark the permanent user as entered — creates an active ticket on their spot"
  def enter_permanent_user(%Parking.Users.PermanentUser{} = perm_user) do
    Repo.transaction(fn ->
      perm_user = Repo.preload(perm_user, :spot)

      active_ticket =
        Repo.one(
          from t in Ticket,
            where: t.permanent_user_id == ^perm_user.id and is_nil(t.exit_time),
            limit: 1
        )

      cond do
        perm_user.spot == nil ->
          Repo.rollback(:no_assigned_spot)

        active_ticket != nil ->
          Repo.rollback(:already_parked)

        true ->
          ticket_changeset =
            Ticket.changeset(%Ticket{}, %{
              "entry_time" => DateTime.truncate(DateTime.utc_now(), :second),
              "spot_id" => perm_user.spot.id,
              "permanent_user_id" => perm_user.id
            })

          with {:ok, _ticket} <- Repo.insert(ticket_changeset) do
            reload_permanent_user(perm_user.id)
          end
      end
    end)
  end

  @doc "Release the permanent user's spot — closes the active ticket"
  def exit_permanent_user(%Parking.Users.PermanentUser{} = perm_user) do
    Repo.transaction(fn ->
      perm_user = Repo.preload(perm_user, :spot)

      active_ticket =
        Repo.one(
          from t in Ticket,
            where: t.permanent_user_id == ^perm_user.id and is_nil(t.exit_time),
            limit: 1
        )

      cond do
        perm_user.spot == nil ->
          Repo.rollback(:no_assigned_spot)

        active_ticket == nil ->
          Repo.rollback(:not_parked)

        true ->
          ticket_changeset =
            Ticket.changeset(active_ticket, %{
              exit_time: DateTime.truncate(DateTime.utc_now(), :second)
            })

          with {:ok, _updated_ticket} <- Repo.update(ticket_changeset) do
            reload_permanent_user(perm_user.id)
          end
      end
    end)
  end

  defp reload_permanent_user(id) do
    from(p in Parking.Users.PermanentUser,
      where: p.id == ^id,
      preload: [:spot, :user]
    )
    |> Repo.one()
  end

  @doc "Get comprehensive garage statistics with all levels and spots"
  def get_garage_stats(garage_id) do
    spots_query =
      from(s in ParkingSpot,
        order_by: [asc: s.id],
        preload: [tickets: :pricing, permanent_user: []]
      )

    levels_query =
      from(l in Level,
        order_by: [asc: l.number],
        preload: [spots: ^spots_query]
      )

    garages =
      from(g in ParkingGarage,
        where: g.id == ^garage_id,
        preload: [levels: ^levels_query]
      )
      |> Repo.one()

    case garages do
      nil ->
        nil

      garage ->
        levels_with_stats =
          Enum.map(garage.levels, fn level ->
            spots_with_type =
              Enum.map(level.spots, fn spot ->
                active_ticket = Enum.find(spot.tickets, &is_nil(&1.exit_time))

                type =
                  cond do
                    spot.permanent_user != nil -> :permanent
                    active_ticket != nil -> :guest_occupied
                    true -> :guest_available
                  end

                Map.put(spot, :spot_type, type)
              end)

            permanent_spots = Enum.count(spots_with_type, &(&1.spot_type == :permanent))
            guest_occupied = Enum.count(spots_with_type, &(&1.spot_type == :guest_occupied))
            guest_available = Enum.count(spots_with_type, &(&1.spot_type == :guest_available))
            total_spots = Enum.count(spots_with_type)

            %{
              level: level,
              spots: spots_with_type,
              total_spots: total_spots,
              permanent_spots: permanent_spots,
              guest_occupied: guest_occupied,
              guest_available: guest_available,
              occupied_spots: permanent_spots + guest_occupied,
              available_spots: guest_available,
              occupancy_rate:
                if(total_spots > 0,
                  do: Float.round((permanent_spots + guest_occupied) / total_spots * 100, 1),
                  else: 0.0
                )
            }
          end)

        all_spots = Enum.flat_map(garage.levels, & &1.spots)
        permanent_spots = Enum.count(all_spots, &(&1.permanent_user != nil))

        guest_occupied =
          Enum.count(
            all_spots,
            &(Enum.any?(&1.tickets, fn t -> is_nil(t.exit_time) end) and &1.permanent_user == nil)
          )

        guest_available =
          Enum.count(
            all_spots,
            &(not Enum.any?(&1.tickets, fn t -> is_nil(t.exit_time) end) and
                &1.permanent_user == nil)
          )

        total_spots = Enum.count(all_spots)

        %{
          garage: garage,
          levels: levels_with_stats,
          total_spots: total_spots,
          permanent_spots: permanent_spots,
          guest_occupied: guest_occupied,
          guest_available: guest_available,
          occupied_spots: permanent_spots + guest_occupied,
          available_spots: guest_available,
          occupancy_rate:
            if(total_spots > 0,
              do: Float.round((permanent_spots + guest_occupied) / total_spots * 100, 1),
              else: 0.0
            )
        }
    end
  end

  @doc "Create a permanent user with an assigned spot and access card for a given garage"
  def create_permanent_user(garage_id, name) do
    spot =
      Repo.one(
        from s in ParkingSpot,
          join: l in Level,
          on: s.level_id == l.id,
          left_join: p in PermanentUser,
          on: p.spot_id == s.id,
          where: l.garage_id == ^garage_id and is_nil(p.id),
          limit: 1
      )

    case spot do
      nil ->
        {:error, :no_spots}

      spot ->
        Repo.transaction(fn ->
          now = DateTime.truncate(DateTime.utc_now(), :second)
          monthly_rent = parse_monthly_rent(garage_id)

          user = Repo.insert!(%User{type: "permanent"})

          perm_user =
            Repo.insert!(%PermanentUser{
              id: user.id,
              access_code: Ecto.UUID.generate(),
              is_blocked: false,
              spot_id: spot.id,
              name: name
            })

          ticket =
            Ticket.changeset(%Ticket{}, %{
              "entry_time" => now,
              "exit_time" => now,
              "spot_id" => spot.id,
              "permanent_user_id" => perm_user.id
            })
            |> Repo.insert!()

          Payment.changeset(%Payment{}, %{
            "amount" => Decimal.from_float(monthly_rent),
            "ticket_id" => ticket.id
          })
          |> Repo.insert!()

          perm_user
          |> PermanentUser.changeset(%{
            rent_paid_until: end_of_month(Date.utc_today()),
            last_rent_payment_at: now
          })
          |> Repo.update!()
        end)
    end
  end

  @doc "List spots in a garage not reserved by any permanent user and not occupied by a guest"
  def list_unassigned_spots(garage_id) do
    active_guest_spot_ids =
      from(t in Ticket,
        where: is_nil(t.exit_time) and is_nil(t.permanent_user_id),
        select: t.spot_id
      )

    from(s in ParkingSpot,
      join: l in Level,
      on: s.level_id == l.id,
      where:
        l.garage_id == ^garage_id and
          s.id not in subquery(active_guest_spot_ids) and
          s.id not in subquery(
            from p in PermanentUser, where: not is_nil(p.spot_id), select: p.spot_id
          ),
      order_by: [asc: s.id]
    )
    |> Repo.all()
  end

  @doc "Reassign a permanent user to a different spot (only when not currently parked)"
  def assign_spot(%PermanentUser{} = perm_user, spot_id) when is_integer(spot_id) do
    perm_user
    |> PermanentUser.changeset(%{spot_id: spot_id})
    |> Repo.update()
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

  @doc "Find a ticket by UUID for display purposes"
  def find_ticket(uuid) do
    from(t in Ticket,
      where: t.id == ^uuid,
      preload: [:spot, :pricing]
    )
    |> Repo.one()
  end
end
