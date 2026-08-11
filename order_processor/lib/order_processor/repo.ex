defmodule OrderProcessor.Repo do
  use Ecto.Repo,
    otp_app: :order_processor,
    adapter: Ecto.Adapters.Postgres
end
