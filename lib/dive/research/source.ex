defmodule Dive.Research.Source do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sources" do
    field :title, :string
    field :url, :string
    field :crawl_task_id, :string
    field :raw, :string
    field :summary, :string
    field :search, :string

    belongs_to :topic, Dive.Research.Topic

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(source, attrs) do
    source
    |> cast(attrs, [:url, :raw, :summary, :search, :topic_id, :crawl_task_id, :title])
    |> validate_required([:url, :search, :topic_id, :title])
  end
end
