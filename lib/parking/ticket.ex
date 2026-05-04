# lib/parking/ticket.ex
defmodule Parking.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :id

  schema "ticket" do
    field :entry_time, :utc_datetime
    field :exit_time, :utc_datetime, default: nil
    field :paid, :boolean, default: false
    belongs_to :spot, Parking.ParkingSpot, foreign_key: :spot_id, type: :id
    belongs_to :pricing, Parking.Pricing, foreign_key: :pricing_id, type: :id

    belongs_to :permanent_user, Parking.Users.PermanentUser,
      foreign_key: :permanent_user_id,
      type: :id

    has_many :payments, Parking.Payment, foreign_key: :ticket_id
    timestamps()
  end

  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:entry_time, :exit_time, :paid, :spot_id, :pricing_id, :permanent_user_id])
    |> validate_required([:entry_time, :spot_id])
    |> validate_required_if_guest()
    |> assoc_constraint(:spot)
    |> assoc_constraint(:pricing)
    |> assoc_constraint(:permanent_user)
  end

  defp validate_required_if_guest(changeset) do
    permanent_user_id = get_field(changeset, :permanent_user_id)

    if is_nil(permanent_user_id) do
      validate_required(changeset, [:pricing_id])
    else
      changeset
    end
  end

end
