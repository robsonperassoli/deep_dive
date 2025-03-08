defmodule Dive.ResearchTest do
  use Dive.DataCase

  alias Dive.Research

  describe "topics" do
    alias Dive.Research.Topic

    import Dive.ResearchFixtures

    @invalid_attrs %{text: nil}

    test "list_topics/0 returns all topics" do
      topic = topic_fixture()
      assert Research.list_topics() == [topic]
    end

    test "get_topic!/1 returns the topic with given id" do
      topic = topic_fixture()
      assert Research.get_topic!(topic.id) == topic
    end

    test "create_topic/1 with valid data creates a topic" do
      valid_attrs = %{text: "some text"}

      assert {:ok, %Topic{} = topic} = Research.create_topic(valid_attrs)
      assert topic.text == "some text"
    end

    test "create_topic/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Research.create_topic(@invalid_attrs)
    end

    test "update_topic/2 with valid data updates the topic" do
      topic = topic_fixture()
      update_attrs = %{text: "some updated text"}

      assert {:ok, %Topic{} = topic} = Research.update_topic(topic, update_attrs)
      assert topic.text == "some updated text"
    end

    test "update_topic/2 with invalid data returns error changeset" do
      topic = topic_fixture()
      assert {:error, %Ecto.Changeset{}} = Research.update_topic(topic, @invalid_attrs)
      assert topic == Research.get_topic!(topic.id)
    end

    test "delete_topic/1 deletes the topic" do
      topic = topic_fixture()
      assert {:ok, %Topic{}} = Research.delete_topic(topic)
      assert_raise Ecto.NoResultsError, fn -> Research.get_topic!(topic.id) end
    end

    test "change_topic/1 returns a topic changeset" do
      topic = topic_fixture()
      assert %Ecto.Changeset{} = Research.change_topic(topic)
    end
  end

  describe "sources" do
    alias Dive.Research.Source

    import Dive.ResearchFixtures

    @invalid_attrs %{raw: nil, url: nil, summarized: nil}

    test "list_sources/0 returns all sources" do
      source = source_fixture()
      assert Research.list_sources() == [source]
    end

    test "get_source!/1 returns the source with given id" do
      source = source_fixture()
      assert Research.get_source!(source.id) == source
    end

    test "create_source/1 with valid data creates a source" do
      valid_attrs = %{raw: "some raw", url: "some url", summarized: "some summarized"}

      assert {:ok, %Source{} = source} = Research.create_source(valid_attrs)
      assert source.raw == "some raw"
      assert source.url == "some url"
      assert source.summarized == "some summarized"
    end

    test "create_source/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Research.create_source(@invalid_attrs)
    end

    test "update_source/2 with valid data updates the source" do
      source = source_fixture()
      update_attrs = %{raw: "some updated raw", url: "some updated url", summarized: "some updated summarized"}

      assert {:ok, %Source{} = source} = Research.update_source(source, update_attrs)
      assert source.raw == "some updated raw"
      assert source.url == "some updated url"
      assert source.summarized == "some updated summarized"
    end

    test "update_source/2 with invalid data returns error changeset" do
      source = source_fixture()
      assert {:error, %Ecto.Changeset{}} = Research.update_source(source, @invalid_attrs)
      assert source == Research.get_source!(source.id)
    end

    test "delete_source/1 deletes the source" do
      source = source_fixture()
      assert {:ok, %Source{}} = Research.delete_source(source)
      assert_raise Ecto.NoResultsError, fn -> Research.get_source!(source.id) end
    end

    test "change_source/1 returns a source changeset" do
      source = source_fixture()
      assert %Ecto.Changeset{} = Research.change_source(source)
    end
  end
end
