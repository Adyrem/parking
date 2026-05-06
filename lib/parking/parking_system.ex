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

  alias Parking.Settings
  alias Parking.Pricing.TimeBasedPricing
  alias Parking.Pricing.PricingStrategy
  alias Parking.Services.PaymentService
  alias Parking.Services.AccountingService
  alias Parking.Users.User

  @doc "Create a new ticket, assign a parking spot, and persist to database"
  def create_ticket(garage_id, pricing_id) do
    Repo.transaction(fn ->
      # Get the first guest-available spot
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
              "pricing_id" => pricing_id,
              "paid" => false
            })

          with {:ok, ticket} <- Repo.insert(ticket_changeset) do
            spot_changeset =
              ParkingSpot.changeset(spot, %{is_occupied: true})

            with {:ok, _} <- Repo.update(spot_changeset) do
              Repo.preload(ticket, [:spot, :pricing])
            end
          end
      end
    end)
  end

  defp guest_spot_query(garage_id) do
    # Count spots per level that are unavailable to guests:
    # either currently occupied, or permanently reserved (even when temporarily free).
    level_occupancy =
      from(s in ParkingSpot,
        join: l in Level,
        on: s.level_id == l.id,
        where:
          l.garage_id == ^garage_id and
            (s.is_occupied or s.id in subquery(from p in PermanentUser, select: p.spot_id)),
        group_by: l.id,
        select: %{level_id: l.id, occupied_count: count(s.id)}
      )

    from(s in ParkingSpot,
      join: l in Level,
      on: s.level_id == l.id,
      left_join: lo in subquery(level_occupancy),
      on: lo.level_id == l.id,
      where:
        l.garage_id == ^garage_id and not s.is_occupied and
          s.id not in subquery(from p in PermanentUser, select: p.spot_id),
      order_by: [asc: coalesce(lo.occupied_count, 0), asc: s.id],
      select: s
    )
  end

  @doc "Get the guest parking status excluding permanent reserved spots"
  def guest_parking_status(garage_id) do
    spots =
      from(s in ParkingSpot,
        join: l in Level,
        on: s.level_id == l.id,
        where:
          l.garage_id == ^garage_id and
            s.id not in subquery(from p in PermanentUser, select: p.spot_id),
        select: %{is_occupied: s.is_occupied}
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
    ticket = Repo.preload(ticket, [:pricing, :permanent_user])

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
        strategy = %TimeBasedPricing{
          time_slots: pricing.config["time_slots"],
          weekend_time_slots: pricing.config["weekend_time_slots"],
          holiday_time_slots: pricing.config["holiday_time_slots"],
          holidays: pricing.config["holidays"] || [],
          daily_rate: pricing.config["daily_rate"],
          default_rate_per_hour: pricing.config["rate_per_hour"]
        }

        PricingStrategy.calculate(strategy, ticket)

      "flat_rate" ->
        strategy = %Parking.Pricing.FlatRatePricing{
          daily_rate: pricing.config["daily_rate"]
        }

        PricingStrategy.calculate(strategy, ticket)

      _ ->
        0.0
    end
  end

  @doc "Process payment for a ticket - updates ticket and creates payment record"
  def process_payment(ticket) do
    Repo.transaction(fn ->
      amount = calculate_fee(ticket)

      # Try to process payment — rollback the transaction on failure
      case PaymentService.process(nil, amount) do
        {:ok, _} -> :ok
        {:error, reason} -> Repo.rollback(reason)
      end

      # Update ticket to mark as paid
      ticket_changeset =
        Ticket.changeset(ticket, %{paid: true})

      with {:ok, updated_ticket} <- Repo.update(ticket_changeset) do
        # Record payment
        payment_changeset =
          Payment.changeset(%Payment{}, %{
            "amount" => Decimal.from_float(amount),
            "timestamp" => DateTime.truncate(DateTime.utc_now(), :second),
            "ticket_id" => updated_ticket.id
          })

        with {:ok, _payment} <- Repo.insert(payment_changeset) do
          # Record in accounting service
          AccountingService.record_transaction(nil, amount)
          updated_ticket
        end
      end
    end)
  end

  @doc "Register vehicle exit - update exit time and free the spot"
  def register_exit(ticket) do
    Repo.transaction(fn ->
      # Preload spot
      ticket = Repo.preload(ticket, :spot)

      cond do
        ticket.permanent_user_id == nil and not ticket.paid ->
          Repo.rollback(:payment_required)

        true ->
          # Update ticket with exit time
          ticket_changeset =
            Ticket.changeset(ticket, %{exit_time: DateTime.truncate(DateTime.utc_now(), :second)})

          with {:ok, updated_ticket} <- Repo.update(ticket_changeset) do
            # Free up the parking spot
            spot_changeset =
              ParkingSpot.changeset(updated_ticket.spot, %{is_occupied: false})

            with {:ok, _spot} <- Repo.update(spot_changeset) do
              updated_ticket
            end
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

  @doc "List permanent users for a specific garage"
  def list_permanent_users(garage_id) do
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
    perm_user = Repo.preload(perm_user, :spot)

    Repo.transaction(fn ->
      now = DateTime.truncate(DateTime.utc_now(), :second)
      paid_until = calculate_next_rent_paid_until(perm_user)
      monthly_rent = parse_monthly_rent()

      ticket =
        Ticket.changeset(%Ticket{}, %{
          "entry_time" => now,
          "exit_time" => now,
          "paid" => true,
          "spot_id" => perm_user.spot_id,
          "permanent_user_id" => perm_user.id
        })
        |> Repo.insert!()

      Payment.changeset(%Payment{}, %{
        "amount" => Decimal.from_float(monthly_rent),
        "timestamp" => now,
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

  defp parse_monthly_rent do
    value = Settings.get("monthly_rent") || raise "monthly_rent not configured in settings"

    case Float.parse(value) do
      {amount, _} -> amount
      :error -> raise "monthly_rent setting has invalid value: #{inspect(value)}"
    end
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

  @doc "Mark the permanent user's assigned spot as occupied"
  def enter_permanent_user(%Parking.Users.PermanentUser{} = perm_user) do
    Repo.transaction(fn ->
      perm_user = Repo.preload(perm_user, :spot)

      cond do
        perm_user.spot == nil ->
          Repo.rollback(:no_assigned_spot)

        perm_user.spot.is_occupied ->
          Repo.rollback(:already_parked)

        true ->
          ticket_changeset =
            Ticket.changeset(%Ticket{}, %{
              "entry_time" => DateTime.truncate(DateTime.utc_now(), :second),
              "spot_id" => perm_user.spot.id,
              "permanent_user_id" => perm_user.id,
              "paid" => true
            })

          with {:ok, _ticket} <- Repo.insert(ticket_changeset) do
            perm_user.spot
            |> Parking.ParkingSpot.changeset(%{is_occupied: true})
            |> Repo.update!()

            reload_permanent_user(perm_user.id)
          end
      end
    end)
  end

  @doc "Release the permanent user's assigned spot"
  def exit_permanent_user(%Parking.Users.PermanentUser{} = perm_user) do
    Repo.transaction(fn ->
      perm_user = Repo.preload(perm_user, :spot)

      cond do
        perm_user.spot == nil ->
          Repo.rollback(:no_assigned_spot)

        not perm_user.spot.is_occupied ->
          Repo.rollback(:not_parked)

        true ->
          active_ticket =
            from(t in Ticket,
              where: t.permanent_user_id == ^perm_user.id and is_nil(t.exit_time),
              limit: 1
            )
            |> Repo.one()

          if is_nil(active_ticket) do
            Repo.rollback(:ticket_not_found)
          else
            ticket_changeset =
              Ticket.changeset(active_ticket, %{
                exit_time: DateTime.truncate(DateTime.utc_now(), :second)
              })

            with {:ok, _updated_ticket} <- Repo.update(ticket_changeset) do
              perm_user.spot
              |> Parking.ParkingSpot.changeset(%{is_occupied: false})
              |> Repo.update!()

              reload_permanent_user(perm_user.id)
            end
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
        # Calculate stats per level
        levels_with_stats =
          Enum.map(garage.levels, fn level ->
            spots_with_type =
              Enum.map(level.spots, fn spot ->
                type =
                  cond do
                    spot.permanent_user != nil -> :permanent
                    spot.is_occupied -> :guest_occupied
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

        # Calculate global stats
        all_spots = Enum.flat_map(garage.levels, & &1.spots)
        permanent_spots = Enum.count(all_spots, &(&1.permanent_user != nil))
        guest_occupied = Enum.count(all_spots, &(&1.is_occupied and &1.permanent_user == nil))
        guest_available = Enum.count(all_spots, &(!&1.is_occupied and &1.permanent_user == nil))
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
          monthly_rent = parse_monthly_rent()

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
              "paid" => true,
              "spot_id" => spot.id,
              "permanent_user_id" => perm_user.id
            })
            |> Repo.insert!()

          Payment.changeset(%Payment{}, %{
            "amount" => Decimal.from_float(monthly_rent),
            "timestamp" => now,
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
    from(s in ParkingSpot,
      join: l in Level,
      on: s.level_id == l.id,
      where:
        l.garage_id == ^garage_id and
          not s.is_occupied and
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

  @doc "Get the active pricing configuration for a garage"
  def get_garage_pricing(garage_id) do
    Repo.one(
      from p in Parking.Pricing,
        where: p.garage_id == ^garage_id,
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
