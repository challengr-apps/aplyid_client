defmodule Aplyid.TestRepo do
  use Ecto.Repo,
    otp_app: :aplyid,
    adapter: Ecto.Adapters.Postgres
end
