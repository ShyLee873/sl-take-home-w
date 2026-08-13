defmodule Mix.Tasks.OrderProcessor.PublishSample do
  use Mix.Task

  alias AMQP.{Basic, Channel, Connection}

  @shortdoc "Publishes a sample order to RabbitMQ"
  @requirements ["app.start"]

  @impl Mix.Task
  def run(_args) do
    rabbitmq = Application.fetch_env!(:order_processor, :rabbitmq)

    unique_id = System.unique_integer([:positive])

    payload = %{
      "event_id" => "evt-sample-#{unique_id}",
      "order_number" => "ORD-SAMPLE-#{unique_id}",
      "customer_email" => "sample@example.com",
      "items" => [
        %{
          "sku" => "MUG-BLUE",
          "quantity" => 2,
          "unit_price_cents" => 1500
        },
        %{
          "sku" => "STICKER",
          "quantity" => 3,
          "unit_price_cents" => 250
        }
      ]
    }

    {:ok, connection} = Connection.open(rabbitmq[:url])
    {:ok, channel} = Channel.open(connection)

    :ok =
      Basic.publish(
        channel,
        rabbitmq[:exchange],
        rabbitmq[:routing_key],
        JSON.encode!(payload),
        content_type: "application/json",
        persistent: true
      )

    Mix.shell().info("Published #{payload["order_number"]} to #{rabbitmq[:queue]}")

    Channel.close(channel)
    Connection.close(connection)
  end
end
