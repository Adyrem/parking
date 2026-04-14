defmodule Parking.Repo.Migrations.CreatePayment do
  use Ecto.Migration

  def change do
    create table(:payment, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :amount, :decimal, precision: 10, scale: 2, null: false
      add :timestamp, :utc_datetime, null: false
      add :ticket_id, references(:ticket, on_delete: :delete_all, type: :binary_id), null: false
      timestamps()
    end

    create index(:payment, [:ticket_id])
  end
end
