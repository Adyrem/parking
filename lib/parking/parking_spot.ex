# lib/parking/parking_spot.ex
defmodule Parking.ParkingSpot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "parking_spot" do
    field :is_occupied, :boolean, default: false
    belongs_to :level, Parking.Level, foreign_key: :level_id
    has_many :tickets, Parking.Ticket, foreign_key: :spot_id
    has_one :permanent_user, Parking.Users.PermanentUser, foreign_key: :spot_id
    timestamps()
  end

  def changeset(spot, attrs) do
    spot
    |> cast(attrs, [:is_occupied, :level_id])
    |> validate_required([:level_id])
    |> assoc_constraint(:level)
  end

end
