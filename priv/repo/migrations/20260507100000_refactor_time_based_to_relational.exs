defmodule Parking.Repo.Migrations.RefactorTimeBasedToRelational do
  use Ecto.Migration

  def change do
    create table(:time_slot) do
      add :pricing_id, references(:pricing, on_delete: :delete_all), null: false
      add :from_time, :string, null: false
      add :to_time, :string, null: false
      add :rate_per_hour, :float, null: false
      add :slot_type, :string, null: false
      timestamps()
    end

    create index(:time_slot, [:pricing_id])

    create table(:holiday) do
      add :pricing_id, references(:pricing, on_delete: :delete_all), null: false
      add :date, :date, null: false
      timestamps()
    end

    create index(:holiday, [:pricing_id])

    alter table(:time_based_pricing) do
      remove :time_slots
      remove :weekend_time_slots
      remove :holiday_time_slots
      remove :holidays
      remove :daily_rate
    end
  end
end
