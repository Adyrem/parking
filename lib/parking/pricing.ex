# lib/parking/pricing.ex
defmodule Parking.Pricing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pricing" do
    field :type, :string
    belongs_to :garage, Parking.ParkingGarage, type: :id
    has_many :tickets, Parking.Ticket, foreign_key: :pricing_id
    has_one :time_based_config, Parking.Pricing.TimeBasedConfig, foreign_key: :pricing_id
    has_one :daily_rate_config, Parking.Pricing.DailyRateConfig, foreign_key: :pricing_id
    has_one :monthly_rent_config, Parking.Pricing.MonthlyRentConfig, foreign_key: :pricing_id
    has_many :time_slots, Parking.Pricing.TimeSlot
    has_many :holidays, Parking.Pricing.Holiday
    timestamps()
  end

  def changeset(pricing, attrs) do
    pricing
    |> cast(attrs, [:type, :garage_id])
    |> validate_required([:type])
    |> validate_inclusion(:type, ["time_based", "daily_rate", "monthly_rent"])
    |> assoc_constraint(:garage)
  end
end
