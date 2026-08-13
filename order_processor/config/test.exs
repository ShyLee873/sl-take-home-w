import Config

config :order_processor, OrderProcessor.Repo,
  database: "order_processor_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :order_processor,
  start_rabbit_consumer: false
