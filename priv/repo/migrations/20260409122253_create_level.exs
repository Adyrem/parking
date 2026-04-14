defmodule Parking.Repo.Migrations.CreateLevel do
  use Ecto.Migration

  def change do
    create table(:level) do
      add :number, :integer, null: false
      add :garage_id, references(:parking_garage, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:level, [:garage_id])
  end
end
