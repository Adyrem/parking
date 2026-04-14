defmodule Parking.Repo.Migrations.AddRentTrackingToPermanentUser do
  use Ecto.Migration

  def change do
    alter table(:permanent_user) do
      add :rent_paid_until, :date
      add :last_rent_payment_at, :utc_datetime
    end
  end
end
