defmodule Parking.Repo.Migrations.CreatePricing do
  use Ecto.Migration

  def change do
    create table(:pricing) do
      add :type, :string, null: false
      add :config, :map, null: false
      add :garage_id, references(:parking_garage, on_delete: :delete_all), null: true
      timestamps()
    end

    create index(:pricing, [:garage_id])
  end
end
