defmodule Parking.PermanentParkingTest do
  use Parking.DataCase

  import Ecto.Query

  alias Parking.PermanentParking
  alias Parking.Repo
  alias Parking.ParkingGarage
  alias Parking.Pricing
  alias Parking.Pricing.MonthlyRentConfig
  alias Parking.Ticket
  alias Parking.ParkingSpot
  alias Parking.Level
  alias Parking.Users.PermanentUser

  defp insert_monthly_rent_pricing(garage_id, monthly_rent) do
    pricing = Repo.insert!(%Pricing{garage_id: garage_id, type: "monthly_rent"})
    Repo.insert!(%MonthlyRentConfig{pricing_id: pricing.id, monthly_rent: monthly_rent})
    pricing
  end

  defp active_ticket_exists?(spot_id) do
    Repo.exists?(from t in Ticket, where: t.spot_id == ^spot_id and is_nil(t.exit_time))
  end

  describe "permanent user workflow" do
    setup do
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Test Garage"})
      level = Repo.insert!(%Level{number: 1, garage_id: garage.id})
      spot = Repo.insert!(%ParkingSpot{number: 1, level_id: level.id})

      {:ok, user} = Repo.insert(%Parking.Users.User{type: "permanent"})

      {:ok, perm_user} =
        Repo.insert(%PermanentUser{
          id: user.id,
          name: "Test User",
          access_code: "123456",
          is_blocked: false,
          spot_id: spot.id
        })

      %{garage: garage, perm_user: perm_user, spot: spot}
    end

    test "authentication succeeds with correct code", %{perm_user: perm_user} do
      assert {:ok, authenticated_user} = PermanentParking.authenticate_permanent_user("123456")
      assert authenticated_user.id == perm_user.id
    end

    test "authentication fails with wrong code" do
      assert {:error, :not_found} = PermanentParking.authenticate_permanent_user("wrong_code")
    end

    test "blocked user is rejected", %{perm_user: perm_user} do
      Repo.update!(PermanentUser.changeset(perm_user, %{is_blocked: true}))
      assert {:error, {:blocked, _}} = PermanentParking.authenticate_permanent_user("123456")
    end

    test "permanent user enters successfully", %{perm_user: perm_user} do
      {:ok, _updated_user} = PermanentParking.enter_permanent_user(perm_user)

      ticket = Repo.get_by(Ticket, permanent_user_id: perm_user.id)
      assert ticket
      assert ticket.spot_id == perm_user.spot_id
      refute ticket.exit_time
      assert active_ticket_exists?(perm_user.spot_id)
    end

    test "permanent user exits successfully", %{perm_user: perm_user} do
      {:ok, _} = PermanentParking.enter_permanent_user(perm_user)
      {:ok, _updated_user} = PermanentParking.exit_permanent_user(perm_user)

      ticket = Repo.get_by(Ticket, permanent_user_id: perm_user.id)
      assert ticket.exit_time
      refute active_ticket_exists?(perm_user.spot_id)
    end
  end

  describe "permanent user creation" do
    test "returns error when no free spots are available" do
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Full Garage"})
      level = Repo.insert!(%Level{number: 1, garage_id: garage.id})
      spot = Repo.insert!(%ParkingSpot{number: 1, level_id: level.id})

      {:ok, user} = Repo.insert(%Parking.Users.User{type: "permanent"})

      Repo.insert!(%PermanentUser{
        id: user.id,
        name: "Existing User",
        access_code: Ecto.UUID.generate(),
        is_blocked: false,
        spot_id: spot.id
      })

      assert {:error, :no_spots} = PermanentParking.create_permanent_user(garage.id, "New User")
    end

    test "creates permanent user with monthly rent from pricing sub-table" do
      {:ok, garage} = Repo.insert(%ParkingGarage{name: "Test Garage"})
      level = Repo.insert!(%Level{number: 1, garage_id: garage.id})
      Repo.insert!(%ParkingSpot{number: 1, level_id: level.id})
      insert_monthly_rent_pricing(garage.id, 100.0)

      assert {:ok, perm_user} = PermanentParking.create_permanent_user(garage.id, "New User")
      assert perm_user.name == "New User"
      assert perm_user.rent_paid_until
    end
  end
end
