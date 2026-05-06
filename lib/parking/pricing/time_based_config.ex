defmodule Parking.Pricing.TimeBasedConfig do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "time_based_pricing" do
    field :pricing_id, :id, primary_key: true
    field :rate_per_hour, :float
  end

  def changeset(config, attrs) do
    config
    |> cast(attrs, [:pricing_id, :rate_per_hour])
    |> validate_required([:pricing_id, :rate_per_hour])
  end
end
