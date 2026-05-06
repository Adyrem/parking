defmodule Parking.Pricing.TimeSlot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "time_slot" do
    field :from_time, :string
    field :to_time, :string
    field :rate_per_hour, :float
    field :slot_type, :string
    belongs_to :pricing, Parking.Pricing
    timestamps()
  end

  def changeset(slot, attrs) do
    slot
    |> cast(attrs, [:pricing_id, :from_time, :to_time, :rate_per_hour, :slot_type])
    |> validate_required([:pricing_id, :from_time, :to_time, :rate_per_hour, :slot_type])
    |> validate_inclusion(:slot_type, ["weekday", "weekend", "holiday"])
  end
end
