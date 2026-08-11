import Config

config :order_processor,
  ecto_repos: [OrderProcessor.Repo]

config :order_processor, OrderProcessor.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5433,
  database: "order_processor_dev",
  pool_size: 10
