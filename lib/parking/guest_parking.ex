defmodule Parking.GuestParking do
  import Ecto.Query
  alias Parking.Repo
  alias Parking.Level
  alias Parking.ParkingSpot
  alias Parking.Ticket
  alias Parking.Payment
  alias Parking.Users.PermanentUser
  alias Parking.Pricing.Calculator
  alias Parking.Services.PaymentService
  alias Parking.Services.AccountingService

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
    level_occupancy =
      from(s in ParkingSpot,
        join: l in Level,
        on: s.level_id == l.id,
        where:
          l.garage_id == ^garage_id and
            (s.id in subquery(active_ticket_spot_ids()) or
               s.id in subquery(perm_reserved_spot_ids())),
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
          s.id not in subquery(active_ticket_spot_ids()) and
          s.id not in subquery(perm_reserved_spot_ids()),
      order_by: [asc: coalesce(lo.occupied_count, 0), asc: s.id],
      select: s
    )
  end

  defp active_ticket_spot_ids,
    do: from(t in Ticket, where: is_nil(t.exit_time), select: t.spot_id)

  defp perm_reserved_spot_ids, do: from(p in PermanentUser, select: p.spot_id)

  @doc "Get the guest parking status excluding permanent reserved spots"
  def guest_parking_status(garage_id) do
    spots =
      from(s in ParkingSpot,
        join: l in Level,
        on: s.level_id == l.id,
        where:
          l.garage_id == ^garage_id and
            s.id not in subquery(perm_reserved_spot_ids()),
        select: %{is_occupied: s.id in subquery(active_ticket_spot_ids())}
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

  @doc "Process payment for a ticket - creates a payment record"
  def process_payment(ticket) do
    Repo.transaction(fn ->
      amount = Calculator.calculate_fee(ticket)

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

      if ticket.permanent_user_id == nil and not ticket_paid? do
        Repo.rollback(:payment_required)
      else
        ticket_changeset =
          Ticket.changeset(ticket, %{exit_time: DateTime.truncate(DateTime.utc_now(), :second)})

        with {:ok, updated_ticket} <- Repo.update(ticket_changeset) do
          updated_ticket
        end
      end
    end)
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
