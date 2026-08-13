defmodule OrderProcessor.OrderWorker do
  use GenServer

  alias OrderProcessor.Orders

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)

    genserver_opts = if name, do: [name: name], else: []

    GenServer.start_link(__MODULE__, %{}, genserver_opts)
  end

  def process(payload) do
    process(__MODULE__, payload)
  end

  def process(server, payload) do
    GenServer.call(server, {:process, payload})
  end

  def stats do
    stats(__MODULE__)
  end

  def stats(server) do
    GenServer.call(server, :stats)
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
