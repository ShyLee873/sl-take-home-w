defmodule OrderProcessor.RabbitConsumerTest do
  use ExUnit.Case

  alias AMQP.{Basic, Channel, Connection, Queue}
  alias Ecto.Adapters.SQL.Sandbox
  alias OrderProcessor.Orders.Order
  alias OrderProcessor.{OrderWorker, RabbitConsumer, Repo}

  @moduletag :integration

  setup do
    owner = Sandbox.start_owner!(Repo, shared: true)

    rabbitmq = Application.fetch_env!(:order_processor, :rabbitmq)

    {:ok, connection} = Connection.open(rabbitmq[:url])
    {:ok, channel} = Channel.open(connection)

    {:ok, _} = Queue.purge(channel, rabbitmq[:queue])

    start_supervised!(RabbitConsumer)

    on_exit(fn ->
      Channel.close(channel)
      Connection.close(connection)
      Sandbox.stop_owner(owner)
    end)

    %{
      channel: channel,
      rabbitmq: rabbitmq
    }
  end

  test "consumes valid and invalid RabbitMQ messages", %{
    channel: channel,
    rabbitmq: rabbitmq
  } do
    unique_id = System.unique_integer([:positive])
    starting_stats = OrderWorker.stats()

    first_event_id = "evt-integration-#{unique_id}"
    first_order_number = "ORD-INTEGRATION-#{unique_id}"

    :ok =
      publish(
        channel,
        rabbitmq,
        JSON.encode!(valid_payload(first_event_id, first_order_number))
      )

    first_order = wait_for_order(first_event_id)

    assert first_order.order_number == first_order_number
    assert first_order.total_cents == 3750
    assert length(first_order.items) == 2

    :ok =
      publish(
        channel,
        rabbitmq,
        "{this-is-not-json"
      )

    invalid_event_id = "evt-invalid-#{unique_id}"

    invalid_payload = %{
      "event_id" => invalid_event_id,
      "order_number" => "ORD-INVALID-#{unique_id}",
      "customer_email" => "alice@example.com",
      "items" => [
        %{
          "sku" => "MUG",
          "quantity" => 0,
          "unit_price_cents" => 1500
        }
      ]
    }

    :ok =
      publish(
        channel,
        rabbitmq,
        JSON.encode!(invalid_payload)
      )

    final_event_id = "evt-after-invalid-#{unique_id}"
    final_order_number = "ORD-AFTER-INVALID-#{unique_id}"

    :ok =
      publish(
        channel,
        rabbitmq,
        JSON.encode!(valid_payload(final_event_id, final_order_number))
      )

    final_order = wait_for_order(final_event_id)

    assert final_order.order_number == final_order_number

    assert Repo.get_by(Order, event_id: invalid_event_id) == nil

    stats = OrderWorker.stats()

    assert stats.processed == starting_stats.processed + 2
    assert stats.failed == starting_stats.failed + 1
  end

  defp publish(channel, rabbitmq, payload) do
    Basic.publish(
      channel,
      rabbitmq[:exchange],
      rabbitmq[:routing_key],
      payload,
      content_type: "application/json",
      persistent: true
    )
  end

  defp valid_payload(event_id, order_number) do
    %{
      "event_id" => event_id,
      "order_number" => order_number,
      "customer_email" => "rabbit@example.com",
      "items" => [
        %{
          "sku" => "MUG",
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
  end

  defp wait_for_order(event_id, attempts \\ 50)

  defp wait_for_order(_event_id, 0) do
    flunk("order was not processed before timeout")
  end

  defp wait_for_order(event_id, attempts) do
    case Repo.get_by(Order, event_id: event_id) do
      nil ->
        Process.sleep(100)
        wait_for_order(event_id, attempts - 1)

      order ->
        Repo.preload(order, :items)
    end
  end
end
