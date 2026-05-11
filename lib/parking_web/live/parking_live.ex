# lib/parking_web/live/parking_live.ex
defmodule ParkingWeb.ParkingLive do
  use ParkingWeb, :live_view

  import Ecto.Query

  alias Parking.Repo
  alias Parking.ParkingGarage
  alias Parking.Payment
  alias Parking.Ticket
  alias Parking.GuestParking
  alias Parking.PermanentParking
  alias Parking.Pricing.Calculator

  def mount(params, _session, socket) do
    garage_id = params["garage_id"] || get_default_garage_id()
    garage_id = if is_binary(garage_id), do: String.to_integer(garage_id), else: garage_id

    case Repo.get(ParkingGarage, garage_id) do
      nil ->
        default_garage_id = get_default_garage_id()
        {:ok, push_navigate(socket, to: ~p"/garage/#{default_garage_id}")}

      garage ->
        {:ok,
         socket
         |> assign(
           garages: Repo.all(ParkingGarage),
           ticket: nil,
           ticket_paid: false,
           fee: nil,
           current_fee: nil,
           message: nil,
           authenticated_permanent_user: nil,
           perm_user_parked: false
         )
         |> assign_garage(garage)}
    end
  end

  defp get_default_garage_id do
    case Repo.one(from g in ParkingGarage, order_by: [asc: g.id], limit: 1) do
      nil -> raise "No parking garage configured"
      garage -> garage.id
    end
  end

  def handle_event("select_garage", %{"garage_id" => garage_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/garage/#{garage_id}")}
  end

  def handle_event("enter", _, socket) do
    case GuestParking.create_ticket(socket.assigns.garage_id, socket.assigns.pricing_id) do
      {:ok, ticket} ->
        {:noreply,
         assign(socket,
           ticket: ticket,
           ticket_paid: false,
           fee: nil,
           current_fee: Calculator.calculate_fee(ticket),
           message: "Einfahrt erfolgreich",
           parking_status: GuestParking.guest_parking_status(socket.assigns.garage_id)
         )}

      {:error, :no_available_spots} ->
        {:noreply, assign(socket, message: "Fehler: Keine verfügbaren Parkplätze")}

      {:error, reason} ->
        {:noreply, assign(socket, message: "Fehler: #{inspect(reason)}")}
    end
  end

  def handle_event("pay", _, socket) do
    case socket.assigns.ticket do
      nil ->
        {:noreply, assign(socket, message: "Kein Ticket vorhanden")}

      ticket ->
        case GuestParking.process_payment(ticket) do
          {:ok, paid_ticket} ->
            fee =
              Repo.one(from p in Payment, where: p.ticket_id == ^paid_ticket.id, select: p.amount)

            {:noreply,
             assign(socket,
               ticket: paid_ticket,
               ticket_paid: true,
               fee: fee,
               current_fee: nil,
               message: "Bezahlung erfolgreich",
               parking_status: GuestParking.guest_parking_status(socket.assigns.garage_id)
             )}

          {:error, :payment_failed} ->
            {:noreply, assign(socket, message: "Bezahlung fehlgeschlagen")}

          {:error, reason} ->
            {:noreply, assign(socket, message: "Fehler: #{inspect(reason)}")}
        end
    end
  end

  def handle_event("exit", _, socket) do
    case socket.assigns.ticket do
      nil ->
        {:noreply, assign(socket, message: "Kein Ticket vorhanden")}

      ticket ->
        case GuestParking.register_exit(ticket) do
          {:ok, updated_ticket} ->
            {:noreply,
             assign(socket,
               ticket: updated_ticket,
               message: "Ausfahrt registriert",
               parking_status: GuestParking.guest_parking_status(socket.assigns.garage_id)
             )}

          {:error, reason} ->
            {:noreply, assign(socket, message: "Fehler: #{inspect(reason)}")}
        end
    end
  end

  def handle_event("scan_ticket", %{"uuid" => uuid}, socket) do
    case GuestParking.find_ticket(uuid) do
      nil ->
        {:noreply, assign(socket, message: "Ticket nicht gefunden")}

      ticket ->
        fee = Repo.one(from p in Payment, where: p.ticket_id == ^ticket.id, select: p.amount)
        ticket_paid = fee != nil

        {:noreply,
         assign(socket,
           ticket: ticket,
           ticket_paid: ticket_paid,
           fee: fee,
           current_fee: if(ticket_paid, do: nil, else: Calculator.calculate_fee(ticket)),
           message: "Ticket #{String.slice(uuid, 0..7)}... geladen"
         )}
    end
  end

  def handle_event("permanent_enter", _, socket) do
    case socket.assigns.authenticated_permanent_user do
      nil ->
        {:noreply,
         assign(socket, message: "Fehler: Bitte melden Sie sich zuerst mit einer Karte an")}

      perm_user ->
        case PermanentParking.enter_permanent_user(perm_user) do
          {:ok, updated_user} ->
            {:noreply,
             assign(socket,
               authenticated_permanent_user: updated_user,
               perm_user_parked: true,
               message: "Einfahrt für Dauerparker registriert",
               parking_status: GuestParking.guest_parking_status(socket.assigns.garage_id)
             )}

          {:error, reason} ->
            {:noreply, assign(socket, message: "Fehler: #{error_reason_to_message(reason)}")}
        end
    end
  end

  def handle_event("authenticate_card", %{"card_uuid" => card_uuid}, socket) do
    case PermanentParking.authenticate_permanent_user(card_uuid) do
      {:ok, perm_user} ->
        perm_user_parked =
          Repo.exists?(
            from t in Ticket,
              where: t.permanent_user_id == ^perm_user.id and is_nil(t.exit_time)
          )

        {:noreply,
         assign(socket,
           authenticated_permanent_user: perm_user,
           perm_user_parked: perm_user_parked,
           message: "Dauerparker erfolgreich angemeldet"
         )}

      {:error, {:blocked, _}} ->
        {:noreply, assign(socket, message: "Fehler: Karte ist gesperrt")}

      {:error, :not_found} ->
        {:noreply, assign(socket, message: "Fehler: Ungültige Karte")}
    end
  end

  def handle_event("permanent_exit", _, socket) do
    case socket.assigns.authenticated_permanent_user do
      nil ->
        {:noreply,
         assign(socket, message: "Fehler: Bitte melden Sie sich zuerst mit einer Karte an")}

      perm_user ->
        case PermanentParking.exit_permanent_user(perm_user) do
          {:ok, updated_user} ->
            {:noreply,
             assign(socket,
               authenticated_permanent_user: updated_user,
               perm_user_parked: false,
               message: "Ausfahrt für Dauerparker registriert",
               parking_status: GuestParking.guest_parking_status(socket.assigns.garage_id)
             )}

          {:error, reason} ->
            {:noreply, assign(socket, message: "Fehler: #{error_reason_to_message(reason)}")}
        end
    end
  end

  def handle_event("copy_uuid", %{"uuid" => uuid}, socket) do
    {:noreply, push_event(socket, "copy-to-clipboard", %{uuid: uuid})}
  end

  def handle_event("logout_user", _, socket) do
    {:noreply,
     assign(socket,
       authenticated_permanent_user: nil,
       perm_user_parked: false,
       message: nil
     )}
  end

  defp error_reason_to_message(:no_assigned_spot), do: "Kein zugewiesener Parkplatz gefunden"

  defp error_reason_to_message(:already_parked),
    do: "Der zugewiesene Parkplatz ist bereits belegt"

  defp error_reason_to_message(:not_parked), do: "Der Parkplatz ist derzeit nicht belegt"

  defp error_reason_to_message(:payment_required),
    do: "Bezahlung ist erforderlich, bevor Sie ausfahren können"

  defp error_reason_to_message(reason), do: inspect(reason)

  def duration_in_hours(ticket) do
    if ticket.exit_time && ticket.entry_time do
      seconds = DateTime.diff(ticket.exit_time, ticket.entry_time, :second)
      hours = seconds / 3600
      Float.round(hours, 2)
    else
      0.0
    end
  end

  defp assign_garage(socket, garage) do
    pricing =
      Calculator.get_garage_pricing(garage.id) ||
        raise "No pricing configured for this garage"

    assign(socket,
      garage: garage,
      garage_id: garage.id,
      pricing_id: pricing.id,
      parking_status: GuestParking.guest_parking_status(garage.id)
    )
  end

  def handle_params(%{"garage_id" => garage_id}, _uri, socket) do
    garage_id = String.to_integer(garage_id)

    case Repo.get(ParkingGarage, garage_id) do
      nil ->
        default_garage_id = get_default_garage_id()
        {:noreply, push_navigate(socket, to: ~p"/garage/#{default_garage_id}")}

      garage ->
        {:noreply,
         socket
         |> assign(
           authenticated_permanent_user: nil,
           perm_user_parked: false,
           ticket: nil,
           ticket_paid: false,
           fee: nil,
           current_fee: nil,
           message: nil
         )
         |> assign_garage(garage)}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
