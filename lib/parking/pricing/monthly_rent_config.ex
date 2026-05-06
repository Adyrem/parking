defmodule Parking.Pricing.MonthlyRentConfig do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "monthly_rent_pricing" do
    field :pricing_id, :id, primary_key: true
    field :monthly_rent, :float
  end

  def changeset(config, attrs) do
    config
    |> cast(attrs, [:pricing_id, :monthly_rent])
    |> validate_required([:pricing_id, :monthly_rent])
  end
end
