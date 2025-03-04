defmodule Dive.Repo do
  use Ecto.Repo,
    otp_app: :dive,
    adapter: Ecto.Adapters.Postgres
end
