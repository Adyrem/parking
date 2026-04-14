# lib/parking/users/occasional_user.ex
defmodule Parking.Users.OccasionalUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "occasional_user" do
    belongs_to :user, Parking.Users.User, define_field: false, foreign_key: :id
    timestamps()
  end

  def changeset(occ_user, attrs) do
    occ_user
    |> cast(attrs, [:id])
    |> validate_required([:id])
    |> assoc_constraint(:user)
  end
end
