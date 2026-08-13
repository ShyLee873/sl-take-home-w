defmodule OrderProcessor.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        OrderProcessor.Repo,
        OrderProcessor.OrderWorker
      ] ++ rabbitmq_children()

    opts = [strategy: :one_for_one, name: OrderProcessor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp rabbitmq_children do
    if Application.get_env(:order_processor, :start_rabbit_consumer, true) do
      [OrderProcessor.RabbitConsumer]
    else
      []
    end
  end
end
