defmodule Parking.Repo.Migrations.CreateParkingSpot do
  use Ecto.Migration

  def change do
    create table(:parking_spot) do
      add :is_occupied, :boolean, default: false, null: false
      add :level_id, references(:level, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:parking_spot, [:level_id])
  end
end
