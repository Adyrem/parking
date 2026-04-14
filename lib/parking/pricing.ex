# lib/parking/pricing.ex
defmodule Parking.Pricing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pricing" do
    field :type, :string
    field :config, :map
    belongs_to :garage, Parking.ParkingGarage, type: :id
    has_many :tickets, Parking.Ticket, foreign_key: :pricing_id
    timestamps()
  end

  def changeset(pricing, attrs) do
    pricing
    |> cast(attrs, [:type, :config, :garage_id])
    |> validate_required([:type, :config])
    |> validate_inclusion(:type, ["time_based", "flat_rate"])
    |> assoc_constraint(:garage)
  end
end
