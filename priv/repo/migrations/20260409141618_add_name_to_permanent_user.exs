defmodule Parking.Repo.Migrations.AddNameToPermanentUser do
  use Ecto.Migration

  def change do
    alter table(:permanent_user) do
      add :name, :string
    end
  end
end
