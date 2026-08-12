defmodule OrderProcessor.Orders do
  alias Ecto.Multi
  alias OrderProcessor.Repo
  alias OrderProcessor.Orders.{Order, OrderItem}

  def process_order(%{"items" => items} = payload)
      when is_list(items) and items != [] do
    with {:ok, prepared_items} <- prepare_items(items) do
      total_cents =
        prepared_items
        |> Enum.map(& &1.line_total_cents)
        |> Enum.sum()

      order_attrs = %{
        event_id: payload["event_id"],
        order_number: payload["order_number"],
        customer_email: payload["customer_email"],
        total_cents: total_cents,
        processed_at:
          DateTime.utc_now()
          |> DateTime.truncate(:second)
      }

      Multi.new()
      |> Multi.insert(:order, Order.changeset(%Order{}, order_attrs))
      |> add_item_inserts(prepared_items)
      |> Repo.transact()
      |> normalize_result(payload["event_id"])
    end
  end

  def process_order(_payload), do: {:error, :invalid_payload}

  defp prepare_items(items) do
    Enum.reduce_while(items, {:ok, []}, fn item, {:ok, prepared_items} ->
      case prepare_item(item) do
        {:ok, prepared_item} ->
          {:cont, {:ok, [prepared_item | prepared_items]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, prepared_items} ->
        {:ok, Enum.reverse(prepared_items)}

      error ->
        error
    end
  end

  defp prepare_item(%{
         "sku" => sku,
         "quantity" => quantity,
         "unit_price_cents" => unit_price_cents
       })
       when is_binary(sku) and is_integer(quantity) and is_integer(unit_price_cents) do
    {:ok,
     %{
       sku: sku,
       quantity: quantity,
       unit_price_cents: unit_price_cents,
       line_total_cents: quantity * unit_price_cents
     }}
  end

  defp prepare_item(_item), do: {:error, :invalid_item}

  defp add_item_inserts(multi, items) do
    items
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {item_attrs, index}, multi ->
      Multi.insert(multi, {:item, index}, fn %{order: order} ->
        attrs = Map.put(item_attrs, :order_id, order.id)

        OrderItem.changeset(%OrderItem{}, attrs)
      end)
    end)
  end

  defp normalize_result({:ok, %{order: order}}, _event_id) do
    {:ok, Repo.preload(order, :items)}
  end

  defp normalize_result(
         {:error, _operation, %Ecto.Changeset{} = changeset, _changes},
         event_id
       ) do
    if duplicate_event?(changeset) do
      case Repo.get_by(Order, event_id: event_id) do
        nil ->
          {:error, changeset}

        order ->
          {:ok, Repo.preload(order, :items)}
      end
    else
      {:error, changeset}
    end
  end

  defp duplicate_event?(changeset) do
    Enum.any?(changeset.errors, fn
      {:event_id, {_message, options}} ->
        options[:constraint] == :unique

      _ ->
        false
    end)
  end
end
