defmodule Dive do
  @moduledoc """
  Dive keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def search(topic) do
    Dive.Research.Researcher.search(topic)
  end
end
