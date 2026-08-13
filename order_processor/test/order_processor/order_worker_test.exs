defmodule OrderProcessor.OrderWorkerTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias OrderProcessor.{OrderWorker, Repo}

  setup do
    :ok = Sandbox.checkout(Repo)

    worker = start_supervised!({OrderWorker, name: nil})

    Sandbox.allow(Repo, self(), worker)

    %{worker: worker}
  end

  test "counts successfully processed orders", %{worker: worker} do
    payload = %{
      "event_id" => "evt-worker-success",
      "order_number" => "ORD-WORKER-SUCCESS",
      "customer_email" => "alice@example",
      "items" => [
        %{
          "sku" => "MUG",
          "quantity" => 1,
          "unit_price_cents" => 1500
        }
      ]
    }

    assert %{processed: 0, failed: 0} = OrderWorker.stats(worker)
    assert {:ok, order} = OrderWorker.process(worker, payload)

    assert order.total_cents == 1500
    assert %{processed: 1, failed: 0} = OrderWorker.stats(worker)
  end

  test "counts failed orders", %{worker: worker} do
    payload = %{
      "event_id" => "evt-worker-fail",
      "order_number" => "ORD-WORKER-FAIL",
      "customer_email" => "alice@example.com",
      "items" => [
        %{
          "sku" => "MUG",
          "quantity" => 0,
          "unit_price_cents" => 1500
        }
      ]
    }

    assert %{processed: 0, failed: 0} = OrderWorker.stats(worker)
    assert {:error, _reason} = OrderWorker.process(worker, payload)

    assert %{processed: 0, failed: 1} = OrderWorker.stats(worker)
  end
end
