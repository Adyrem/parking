defmodule Parking.Repo.Migrations.RemovePricingConfig do
  use Ecto.Migration

  def change do
    alter table(:pricing) do
      remove :config
    end
  end
end
