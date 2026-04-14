defmodule Parking.Repo.Migrations.CreateOccasionalUser do
  use Ecto.Migration

  def change do
    create table(:occasional_user, primary_key: false) do
      add :id, references(:user, on_delete: :delete_all), primary_key: true
      timestamps()
    end
  end
end
