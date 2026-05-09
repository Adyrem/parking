# lib/parking/parking_spot.ex
defmodule Parking.ParkingSpot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "parking_spot" do
    field :number, :integer, default: 0
    belongs_to :level, Parking.Level, foreign_key: :level_id
    has_many :tickets, Parking.Ticket, foreign_key: :spot_id
    has_one :permanent_user, Parking.Users.PermanentUser, foreign_key: :spot_id
    timestamps()
  end

  def changeset(spot, attrs) do
    spot
    |> cast(attrs, [:number, :level_id])
    |> validate_required([:number, :level_id])
    |> assoc_constraint(:level)
    |> unique_constraint([:number, :level_id])
  end

end
