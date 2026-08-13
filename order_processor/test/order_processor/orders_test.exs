defmodule OrderProcessor.OrdersTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias OrderProcessor.Orders
  alias OrderProcessor.Orders.Order
  alias OrderProcessor.Repo

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "processes and persists a valid order" do
    payload = valid_payload("evt-test-001", "ORD-TEST-001")

    assert {:ok, order} = Orders.process_order(payload)

    assert order.event_id == "evt-test-001"
    assert order.order_number == "ORD-TEST-001"
    assert order.total_cents == 3750
    assert length(order.items) == 2

    assert Enum.any?(order.items, fn item ->
             item.sku == "MUG-BLUE" and item.line_total_cents == 3000
           end)

    assert Enum.any?(order.items, fn item ->
             item.sku == "STICKER" and item.line_total_cents == 750
           end)
  end

  test "rolls back the order when an item is invalid" do
    payload = %{
      "event_id" => "evt-test-bad",
      "order_number" => "ORD-TEST-BAD",
      "customer_email" => "alice@example.com",
      "items" => [
        %{
          "sku" => "MUG",
          "quantity" => 0,
          "unit_price_cents" => 1500
        }
      ]
    }

    assert {:error, changeset} = Orders.process_order(payload)

    refute changeset.valid?
    assert Repo.get_by(Order, event_id: "evt-test-bad") == nil
  end

  test "processing the same order twice is idempotent" do
    payload = valid_payload("evt-test-duplicate", "ORD-TEST-DUPLICATE")

    assert {:ok, first_order} = Orders.process_order(payload)
    assert {:ok, second_order} = Orders.process_order(payload)

    assert first_order.id == second_order.id
  end

  test "rejects a different order using an existing order number" do
    first_payload = valid_payload("evt-test-og", "ORD-TEST-CONFLICT")
    conflicting_payload = valid_payload("evt-test-other", "ORD-TEST-CONFLICT")

    assert {:ok, _order} = Orders.process_order(first_payload)
    assert {:error, changeset} = Orders.process_order(conflicting_payload)

    assert Keyword.has_key?(changeset.errors, :order_number)
  end

  defp valid_payload(event_id, order_number) do
    %{
      "event_id" => event_id,
      "order_number" => order_number,
      "customer_email" => "alice@example.com",
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
  end
end
