# lib/parking/payment.ex
defmodule Parking.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "payment" do
    field :amount, :decimal
    field :timestamp, :utc_datetime
    belongs_to :ticket, Parking.Ticket
    timestamps()
  end

  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:amount, :timestamp, :ticket_id])
    |> validate_required([:amount, :timestamp, :ticket_id])
    |> validate_number(:amount, greater_than: 0)
    |> assoc_constraint(:ticket)
  end
end
