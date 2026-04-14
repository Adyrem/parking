defmodule Parking.Settings do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Parking.Repo

  schema "settings" do
    field :key, :string
    field :value, :string
    timestamps()
  end

  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
    |> unique_constraint(:key)
  end

  @doc "Fetch the value for a given key, returns nil if not found."
  def get(key) do
    case Repo.one(from s in __MODULE__, where: s.key == ^key) do
      nil -> nil
      setting -> setting.value
    end
  end
end
