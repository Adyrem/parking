# lib/parking/level.ex
defmodule Parking.Level do
  use Ecto.Schema
  import Ecto.Changeset

  schema "level" do
    field :number, :integer
    belongs_to :garage, Parking.ParkingGarage, foreign_key: :garage_id
    has_many :spots, Parking.ParkingSpot, foreign_key: :level_id
    timestamps()
  end

  def changeset(level, attrs) do
    level
    |> cast(attrs, [:number, :garage_id])
    |> validate_required([:number, :garage_id])
    |> assoc_constraint(:garage)
    |> unique_constraint([:number, :garage_id])
  end
end
