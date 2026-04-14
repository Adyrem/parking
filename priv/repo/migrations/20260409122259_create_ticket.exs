defmodule Parking.Repo.Migrations.CreateTicket do
  use Ecto.Migration

  def change do
    create table(:ticket, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entry_time, :utc_datetime, null: false
      add :exit_time, :utc_datetime, null: true
      add :paid, :boolean, default: false, null: false
      add :spot_id, references(:parking_spot, on_delete: :restrict), null: false
      add :pricing_id, references(:pricing, on_delete: :restrict), null: false
      timestamps()
    end

    create index(:ticket, [:spot_id])
    create index(:ticket, [:pricing_id])
  end
end
