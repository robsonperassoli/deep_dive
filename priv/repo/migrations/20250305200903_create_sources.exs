defmodule Dive.Repo.Migrations.CreateSources do
  use Ecto.Migration

  def change do
    create table(:sources) do
      add :url, :text, null: false
      add :crawl_task_id, :text
      add :raw, :text
      add :summary, :text
      add :search, :text, null: false
      add :title, :text
      add :topic_id, references(:topics, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:sources, [:topic_id])
  end
end
