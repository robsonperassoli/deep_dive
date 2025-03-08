defmodule Dive.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :text, :text
      add :report, :text

      timestamps(type: :utc_datetime)
    end
  end
end
