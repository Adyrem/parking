defmodule Parking.Repo.Migrations.AddNumberToParkingSpot do
  use Ecto.Migration

  def change do
    alter table(:parking_spot) do
      add :number, :integer, default: 0, null: false
    end
  end
end
