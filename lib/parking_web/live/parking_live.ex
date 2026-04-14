# lib/parking_web/live/parking_live.ex
defmodule ParkingWeb.ParkingLive do
  use ParkingWeb, :live_view

  import Ecto.Query

  alias Parking.Repo
  alias Parking.ParkingSystem
  alias Parking.ParkingGarage
  alias Parking.Payment

  def mount(params, _session, socket) do
    # Get garage_id from params or default to first garage
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
           fee: nil,
           message: nil,
           authenticated_permanent_user: nil
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
    case ParkingSystem.create_ticket(socket.assigns.garage_id, socket.assigns.pricing_id) do
      {:ok, ticket} ->
        {:noreply,
         assign(socket,
           ticket: ticket,
           fee: nil,
           message: "Einfahrt erfolgreich",
           stats: ParkingSystem.get_garage_stats(socket.assigns.garage_id),
           parking_status: ParkingSystem.guest_parking_status(socket.assigns.garage_id)
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
        case ParkingSystem.process_payment(ticket) do
          {:ok, updated_ticket} ->
            fee =
              Repo.one(
                from p in Payment, where: p.ticket_id == ^updated_ticket.id, select: p.amount
              )

            {:noreply,
             assign(socket,
               ticket: updated_ticket,
               fee: fee,
               message: "Bezahlung erfolgreich",
               stats: ParkingSystem.get_garage_stats(socket.assigns.garage_id),
               parking_status: ParkingSystem.guest_parking_status(socket.assigns.garage_id)
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
        case ParkingSystem.register_exit(ticket) do
          {:ok, updated_ticket} ->
            {:noreply,
             assign(socket,
               ticket: updated_ticket,
               message: "Ausfahrt registriert",
               parking_status: ParkingSystem.guest_parking_status(socket.assigns.garage_id)
             )}

          {:error, reason} ->
            {:noreply, assign(socket, message: "Fehler: #{inspect(reason)}")}
        end
    end
  end

  def handle_event("scan_ticket", %{"uuid" => uuid}, socket) do
    case ParkingSystem.find_ticket(uuid) do
      nil ->
        {:noreply, assign(socket, message: "Ticket nicht gefunden")}

      ticket ->
        {:noreply,
         assign(socket,
           ticket: ticket,
           fee: nil,
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
        case ParkingSystem.enter_permanent_user(perm_user) do
          {:ok, updated_user} ->
            {:noreply,
             assign(socket,
               authenticated_permanent_user: updated_user,
               message: "Einfahrt für permanenten Benutzer registriert",
               stats: ParkingSystem.get_garage_stats(socket.assigns.garage_id),
               parking_status: ParkingSystem.guest_parking_status(socket.assigns.garage_id)
             )}

          {:error, reason} ->
            {:noreply, assign(socket, message: "Fehler: #{error_reason_to_message(reason)}")}
        end
    end
  end

  def handle_event("authenticate_card", %{"card_uuid" => card_uuid}, socket) do
    case ParkingSystem.authenticate_permanent_user(card_uuid) do
      {:ok, perm_user} ->
        {:noreply,
         assign(socket,
           authenticated_permanent_user: perm_user,
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
        case ParkingSystem.exit_permanent_user(perm_user) do
          {:ok, updated_user} ->
            {:noreply,
             assign(socket,
               authenticated_permanent_user: updated_user,
               message: "Ausfahrt für permanenten Benutzer registriert",
               stats: ParkingSystem.get_garage_stats(socket.assigns.garage_id),
               parking_status: ParkingSystem.guest_parking_status(socket.assigns.garage_id)
             )}

          {:error, reason} ->
            {:noreply, assign(socket, message: "Fehler: #{error_reason_to_message(reason)}")}
        end
    end
  end

  def handle_event("logout_user", _, socket) do
    {:noreply,
     assign(socket,
       authenticated_permanent_user: nil,
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

  def perm_user_parked?(user) do
    user != nil and user.spot != nil and user.spot.is_occupied
  end

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
      Repo.one(from p in Parking.Pricing, where: p.garage_id == ^garage.id, limit: 1) ||
        raise "No pricing configured for this garage"

    assign(socket,
      garage: garage,
      garage_id: garage.id,
      pricing_id: pricing.id,
      stats: ParkingSystem.get_garage_stats(garage.id),
      parking_status: ParkingSystem.guest_parking_status(garage.id)
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
         |> assign(authenticated_permanent_user: nil, ticket: nil, fee: nil, message: nil)
         |> assign_garage(garage)}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
