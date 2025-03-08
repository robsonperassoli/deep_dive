defmodule Dive.ResearchFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dive.Research` context.
  """

  @doc """
  Generate a topic.
  """
  def topic_fixture(attrs \\ %{}) do
    {:ok, topic} =
      attrs
      |> Enum.into(%{
        text: "some text"
      })
      |> Dive.Research.create_topic()

    topic
  end

  @doc """
  Generate a source.
  """
  def source_fixture(attrs \\ %{}) do
    {:ok, source} =
      attrs
      |> Enum.into(%{
        raw: "some raw",
        summarized: "some summarized",
        url: "some url"
      })
      |> Dive.Research.create_source()

    source
  end
end
