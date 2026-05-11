defmodule Parking.PermanentParking do
  import Ecto.Query
  alias Parking.Repo
  alias Parking.Level
  alias Parking.ParkingSpot
  alias Parking.Ticket
  alias Parking.Payment
  alias Parking.Users.PermanentUser
  alias Parking.Users.User
  alias Parking.Pricing.MonthlyRentConfig

  @doc "Authenticate a permanent user by access code"
  def authenticate_permanent_user(code) when is_binary(code) do
    case Repo.one(from p in PermanentUser, where: p.access_code == ^code, preload: [:spot, :user]) do
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

  defp maybe_enforce_rent_block(%PermanentUser{} = perm_user) do
    if PermanentUser.rent_due?(perm_user) and not perm_user.is_blocked do
      perm_user
      |> PermanentUser.changeset(%{is_blocked: true})
      |> Repo.update!()
    else
      perm_user
    end
  end

  @doc "Mark the permanent user as entered — creates an active ticket on their spot"
  def enter_permanent_user(%PermanentUser{} = perm_user) do
    Repo.transaction(fn ->
      perm_user = Repo.preload(perm_user, :spot)
      active_ticket = active_ticket_for(perm_user)

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
  def exit_permanent_user(%PermanentUser{} = perm_user) do
    Repo.transaction(fn ->
      perm_user = Repo.preload(perm_user, :spot)
      active_ticket = active_ticket_for(perm_user)

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

  defp active_ticket_for(%PermanentUser{id: id}) do
    Repo.one(
      from t in Ticket, where: t.permanent_user_id == ^id and is_nil(t.exit_time), limit: 1
    )
  end

  defp reload_permanent_user(id) do
    Repo.one(from p in PermanentUser, where: p.id == ^id, preload: [:spot, :user])
  end

  @doc "List permanent users for a specific garage, with is_parked derived from active tickets"
  def list_permanent_users(garage_id) do
    users =
      from(p in PermanentUser,
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

          insert_rent_record(spot.id, perm_user.id, monthly_rent, now)

          perm_user
          |> PermanentUser.changeset(%{
            rent_paid_until: end_of_month(Date.utc_today()),
            last_rent_payment_at: now
          })
          |> Repo.update!()
        end)
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

      insert_rent_record(perm_user.spot_id, perm_user.id, monthly_rent, now)

      perm_user
      |> PermanentUser.changeset(%{
        is_blocked: false,
        rent_paid_until: paid_until,
        last_rent_payment_at: now
      })
      |> Repo.update!()
    end)
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

  @doc "Reassign a permanent user to a different spot"
  def assign_spot(%PermanentUser{} = perm_user, spot_id) when is_integer(spot_id) do
    perm_user
    |> PermanentUser.changeset(%{spot_id: spot_id})
    |> Repo.update()
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

  defp insert_rent_record(spot_id, perm_user_id, amount, now) do
    ticket =
      Ticket.changeset(%Ticket{}, %{
        "entry_time" => now,
        "exit_time" => now,
        "spot_id" => spot_id,
        "permanent_user_id" => perm_user_id
      })
      |> Repo.insert!()

    Payment.changeset(%Payment{}, %{
      "amount" => Decimal.from_float(amount),
      "ticket_id" => ticket.id
    })
    |> Repo.insert!()
  end

  defp calculate_next_rent_paid_until(%PermanentUser{rent_paid_until: nil}) do
    end_of_month(Date.utc_today())
  end

  defp calculate_next_rent_paid_until(%PermanentUser{rent_paid_until: paid_until}) do
    today = Date.utc_today()
    current_month_start = %Date{year: today.year, month: today.month, day: 1}

    if Date.compare(paid_until, current_month_start) == :lt do
      end_of_month(today)
    else
      next_month_end(paid_until)
    end
  end

  defp next_month_end(%Date{year: year, month: 12}),
    do: end_of_month(%Date{year: year + 1, month: 1, day: 1})

  defp next_month_end(%Date{year: year, month: month}),
    do: end_of_month(%Date{year: year, month: month + 1, day: 1})

  defp end_of_month(%Date{year: year, month: month}) do
    %Date{
      year: year,
      month: month,
      day: Date.days_in_month(%Date{year: year, month: month, day: 1})
    }
  end
end
