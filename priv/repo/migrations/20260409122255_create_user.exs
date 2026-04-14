defmodule Parking.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:user) do
      add :type, :string, null: false
      timestamps()
    end
  end
end
