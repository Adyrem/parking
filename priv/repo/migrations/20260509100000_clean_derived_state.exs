defmodule Parking.Repo.Migrations.CleanDerivedState do
  use Ecto.Migration

  def change do
    alter table(:parking_spot) do
      remove :is_occupied, :boolean
    end

    alter table(:ticket) do
      remove :paid, :boolean
    end

    alter table(:payment) do
      remove :timestamp, :utc_datetime
    end

    create unique_index(:permanent_user, [:access_code])
    drop index(:permanent_user, [:spot_id])
    create unique_index(:permanent_user, [:spot_id])
    create unique_index(:parking_spot, [:number, :level_id])
    create unique_index(:level, [:number, :garage_id])
    create unique_index(:time_slot, [:pricing_id, :slot_type, :from_time, :to_time])
    create unique_index(:holiday, [:pricing_id, :date])
  end
end
