defmodule OrderProcessor.RabbitConsumer do
  use GenServer

  require Logger

  alias AMQP.{Basic, Channel, Connection}
  alias OrderProcessor.OrderWorker

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    rabbitmq = Application.fetch_env!(:order_processor, :rabbitmq)

    {:ok, connection} = Connection.open(rabbitmq[:url])
    {:ok, channel} = Channel.open(connection)

    :ok = Basic.qos(channel, prefetch_count: 1)
    {:ok, _consumer_tag} = Basic.consume(channel, rabbitmq[:queue])

    channel_monitor = Process.monitor(channel.pid)

    Logger.info("Connecting RabbitMQ consumer to #{rabbitmq[:queue]}")

    {:ok,
     %{
       connection: connection,
       channel: channel,
       channel_monitor: channel_monitor,
       consumer_tag: nil
     }}
  end

  @impl true
  def handle_info(
        {:basic_consume_ok, %{consumer_tag: consumer_tag}},
        state
      ) do
    Logger.info("RabbitMQ consumer registered")

    {:noreply, %{state | consumer_tag: consumer_tag}}
  end

  @impl true
  def handle_info(
        {:basic_deliver, payload, %{delivery_tag: delivery_tag}},
        state
      ) do
    handle_delivery(payload, delivery_tag, state.channel)

    {:noreply, state}
  end

  @impl true
  def handle_info({:basic_cancel, _meta}, state) do
    {:stop, :rabbitmq_consumer_cancelled, state}
  end

  @impl true
  def handle_info(
        {:DOWN, monitor_ref, :process, _pid, reason},
        %{channel_monitor: monitor_ref} = state
      ) do
    {:stop, {:rabbitmq_channel_down, reason}, state}
  end

  @impl true
  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    Connection.close(state.connection)
    :ok
  end

  defp handle_delivery(payload, delivery_tag, channel) do
    case JSON.decode(payload) do
      {:ok, decoded_payload} ->
        process_order(decoded_payload, delivery_tag, channel)

      {:error, reason} ->
        Logger.warning("Rejecting malformed JSON: #{inspect(reason)}")

        Basic.reject(channel, delivery_tag, requeue: false)
    end
  end

  defp process_order(payload, delivery_tag, channel) do
    case OrderWorker.process(payload) do
      {:ok, order} ->
        :ok = Basic.ack(channel, delivery_tag)

        Logger.info("Processed order #{order.order_number} (#{order.total_cents} cents)")

      {:error, reason} ->
        :ok = Basic.reject(channel, delivery_tag, requeue: false)

        Logger.warning("Rejecting invalid order: #{inspect(reason)}")
    end
  catch
    :exit, reason ->
      Logger.error("Order processing crashed; requeueing message: #{inspect(reason)}")

      Basic.nack(channel, delivery_tag, requeue: true)
  end
end
