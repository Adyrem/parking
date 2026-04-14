# lib/parking/users/user.ex
defmodule Parking.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user" do
    field :type, :string
    has_one :permanent_user, Parking.Users.PermanentUser, foreign_key: :id, references: :id
    has_one :occasional_user, Parking.Users.OccasionalUser, foreign_key: :id, references: :id
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:type])
    |> validate_required([:type])
    |> validate_inclusion(:type, ["permanent", "occasional"])
  end
end
