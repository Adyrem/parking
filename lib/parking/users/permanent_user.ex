# lib/parking/users/permanent_user.ex
defmodule Parking.Users.PermanentUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permanent_user" do
    field :access_code, :string
    field :name, :string
    field :is_blocked, :boolean, default: false
    field :rent_paid_until, :date
    field :last_rent_payment_at, :utc_datetime
    belongs_to :user, Parking.Users.User, define_field: false, foreign_key: :id
    belongs_to :spot, Parking.ParkingSpot, type: :id
    timestamps()
  end

  def changeset(perm_user, attrs) do
    perm_user
    |> cast(attrs, [
      :access_code,
      :is_blocked,
      :id,
      :spot_id,
      :name,
      :rent_paid_until,
      :last_rent_payment_at
    ])
    |> validate_required([:access_code, :id])
  end

  def validate_code(%__MODULE__{access_code: code, is_blocked: blocked}, input) do
    code == input and not blocked
  end

  def rent_due?(perm_user, today \\ Date.utc_today())

  def rent_due?(%__MODULE__{rent_paid_until: nil}, today) do
    today.day >= 15
  end

  def rent_due?(%__MODULE__{rent_paid_until: paid_until}, today) do
    current_month_start = %Date{year: today.year, month: today.month, day: 1}

    Date.compare(paid_until, current_month_start) == :lt and today.day >= 15
  end
end
