defmodule Parking.Repo.Migrations.CreatePermanentUser do
  use Ecto.Migration

  def change do
    create table(:permanent_user, primary_key: false) do
      add :id, references(:user, on_delete: :delete_all), primary_key: true
      add :access_code, :string, null: false
      add :is_blocked, :boolean, default: false, null: false
      add :spot_id, references(:parking_spot, on_delete: :nilify_all), null: true
      timestamps()
    end

    create index(:permanent_user, [:spot_id])
  end
end
