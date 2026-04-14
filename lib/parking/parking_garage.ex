# lib/parking/parking_garage.ex
defmodule Parking.ParkingGarage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "parking_garage" do
    field :name, :string
    has_many :levels, Parking.Level, foreign_key: :garage_id
    has_many :pricings, Parking.Pricing, foreign_key: :garage_id
    timestamps()
  end

  def changeset(garage, attrs) do
    garage
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
