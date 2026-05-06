defmodule Parking.Pricing.DailyRateConfig do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "daily_rate_pricing" do
    field :pricing_id, :id, primary_key: true
    field :daily_rate, :float
  end

  def changeset(config, attrs) do
    config
    |> cast(attrs, [:pricing_id, :daily_rate])
    |> validate_required([:pricing_id, :daily_rate])
  end
end
