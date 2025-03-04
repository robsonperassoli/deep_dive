defmodule DiveWeb.ErrorJSONTest do
  use DiveWeb.ConnCase, async: true

  test "renders 404" do
    assert DiveWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert DiveWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
