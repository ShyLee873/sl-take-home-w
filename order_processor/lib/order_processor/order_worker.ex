defmodule OrderProcessor.OrderWorker do
  use GenServer

  alias OrderProcessor.Orders

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def process(payload) do
    GenServer.call(__MODULE__, {:process, payload})
  end

  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def init(_initial_state) do
    {:ok, %{processed: 0, failed: 0}}
  end

  @impl true
  def handle_call({:process, payload}, _from, state) do
    result = Orders.process_order(payload)

    new_state =
      case result do
        {:ok, _order} ->
          %{state | processed: state.processed + 1}

        {:error, _reason} ->
          %{state | failed: state.failed + 1}
      end

    {:reply, result, new_state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end
end
