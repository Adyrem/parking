defmodule Parking.Repo.Migrations.CreatePricingSubTables do
  use Ecto.Migration

  def change do
    create table(:time_based_pricing, primary_key: false) do
      add :pricing_id, references(:pricing, on_delete: :delete_all), primary_key: true
      add :time_slots, :map, null: false
      add :weekend_time_slots, :map
      add :holiday_time_slots, :map
      add :holidays, :map
      add :rate_per_hour, :float, null: false, default: 0.0
      add :daily_rate, :float, null: false, default: 0.0
    end

    create table(:daily_rate_pricing, primary_key: false) do
      add :pricing_id, references(:pricing, on_delete: :delete_all), primary_key: true
      add :daily_rate, :float, null: false
    end

    create table(:monthly_rent_pricing, primary_key: false) do
      add :pricing_id, references(:pricing, on_delete: :delete_all), primary_key: true
      add :monthly_rent, :float, null: false
    end
  end
end
