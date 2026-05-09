defmodule Parking.Pricing.Holiday do
  use Ecto.Schema
  import Ecto.Changeset

  schema "holiday" do
    field :date, :date
    belongs_to :pricing, Parking.Pricing
    timestamps()
  end

  def changeset(holiday, attrs) do
    holiday
    |> cast(attrs, [:pricing_id, :date])
    |> validate_required([:pricing_id, :date])
    |> unique_constraint([:pricing_id, :date])
  end
end
