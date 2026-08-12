defmodule OrderProcessor.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OrderProcessor.Repo,
      OrderProcessor.OrderWorker,
      OrderProcessor.RabbitConsumer
    ]

    opts = [strategy: :one_for_one, name: OrderProcessor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
