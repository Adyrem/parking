defmodule Parking.Repo.Migrations.AddPermanentUserIdToTicket do
  use Ecto.Migration

  def change do
    # Drop the existing foreign key constraint
    drop constraint(:ticket, "ticket_pricing_id_fkey")

    # Make pricing_id nullable
    alter table(:ticket) do
      modify :pricing_id, :id, null: true
    end

    # Add the foreign key constraint back with null allowed
    alter table(:ticket) do
      modify :pricing_id, references(:pricing, on_delete: :restrict), null: true
      add :permanent_user_id, references(:permanent_user, on_delete: :nilify_all), null: true
    end

    create index(:ticket, [:permanent_user_id])
  end
end
