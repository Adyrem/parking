defmodule ParkingWeb.AdminLive do
  use ParkingWeb, :live_view

  import Ecto.Query

  alias Parking.Repo
  alias Parking.ParkingSystem
  alias Parking.ParkingGarage
  alias Parking.Users.PermanentUser

  def mount(_params, _session, socket) do
    garages = Repo.all(from g in ParkingGarage, order_by: [asc: g.id])

    default_garage_id =
      case garages do
        [first | _] -> first.id
        [] -> nil
      end

    {:ok,
     assign(socket,
       admin_authenticated: false,
       admin_message: nil,
       admin_error: nil,
       perm_users: [],
       garages: garages,
       garage_id: default_garage_id
     )}
  end

  def handle_params(%{"garage_id" => garage_id}, _uri, socket) do
    garage_id = String.to_integer(garage_id)

    perm_users =
      if socket.assigns.admin_authenticated,
        do: ParkingSystem.list_permanent_users(garage_id),
        else: []

    {:noreply, assign(socket, garage_id: garage_id, perm_users: perm_users)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def handle_event("select_garage", %{"garage_id" => garage_id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin?garage_id=#{garage_id}")}
  end

  def handle_event("login", %{"admin_password" => password}, socket) do
    if password == Parking.Settings.get("admin_password") do
      {:noreply,
       assign(socket,
         admin_authenticated: true,
         admin_message: "Admin erfolgreich angemeldet",
         admin_error: nil,
         perm_users: ParkingSystem.list_permanent_users(socket.assigns.garage_id)
       )}
    else
      {:noreply,
       assign(socket,
         admin_authenticated: false,
         admin_message: nil,
         admin_error: "Ungültiges Admin-Passwort"
       )}
    end
  end

  def handle_event("logout", _, socket) do
    {:noreply,
     assign(socket,
       admin_authenticated: false,
       admin_message: nil,
       admin_error: nil,
       perm_users: []
     )}
  end

  def handle_event("refresh", _, socket) do
    if socket.assigns.admin_authenticated do
      {:noreply,
       assign(socket,
         perm_users: ParkingSystem.list_permanent_users(socket.assigns.garage_id),
         admin_message: "Dauerparkerliste aktualisiert",
         admin_error: nil
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_event("add_user", %{"name" => name}, socket) do
    if socket.assigns.admin_authenticated do
      garage_id = socket.assigns.garage_id

      case ParkingSystem.create_permanent_user(garage_id, name) do
        {:ok, perm_user} ->
          {:noreply,
           assign(socket,
             perm_users: ParkingSystem.list_permanent_users(garage_id),
             admin_message: "Dauerparker erfolgreich hinzugefügt. UUID: #{perm_user.access_code}",
             admin_error: nil
           )}

        {:error, :no_spots} ->
          {:noreply,
           assign(socket,
             admin_error: "Keine freien Parkplätze verfügbar",
             admin_message: nil
           )}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("pay_rent", %{"user_id" => user_id}, socket) do
    if socket.assigns.admin_authenticated do
      perm_user = Repo.get!(PermanentUser, user_id)

      case ParkingSystem.process_rent_payment(perm_user) do
        {:ok, updated_user} ->
          {:noreply,
           assign(socket,
             perm_users: ParkingSystem.list_permanent_users(socket.assigns.garage_id),
             admin_message: "Miete wurde erfolgreich bezahlt für #{updated_user.name}",
             admin_error: nil
           )}

        {:error, _reason} ->
          {:noreply,
           assign(socket,
             admin_error: "Fehler beim Verarbeiten der Miete",
             admin_message: nil
           )}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_block", %{"user_id" => user_id}, socket) do
    if socket.assigns.admin_authenticated do
      perm_user = Repo.get!(PermanentUser, user_id)
      Repo.update!(PermanentUser.changeset(perm_user, %{is_blocked: not perm_user.is_blocked}))

      {:noreply,
       assign(socket,
         perm_users: ParkingSystem.list_permanent_users(socket.assigns.garage_id),
         admin_message: "Benutzerstatus aktualisiert",
         admin_error: nil
       )}
    else
      {:noreply, socket}
    end
  end
end
