defmodule Dive.Research.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topics" do
    field :text, :string
    field :report, :string
    has_many :sources, Dive.Research.Source

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:text, :report])
    |> validate_required([:text])
  end
end
