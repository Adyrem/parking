defmodule Parking.Repo.Migrations.CreateParkingGarage do
  use Ecto.Migration

  def change do
    create table(:parking_garage) do
      add :name, :string, null: false
      timestamps()
    end
  end
end
