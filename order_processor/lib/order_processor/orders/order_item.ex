defmodule OrderProcessor.Orders.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias OrderProcessor.Orders.Order

  @timestamps_opts [type: :utc_datetime]

  schema "order_items" do
    field(:sku, :string)
    field(:quantity, :integer)
    field(:unit_price_cents, :integer)
    field(:line_total_cents, :integer)

    belongs_to(:order, Order)

    timestamps()
  end

  def changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [
      :order_id,
      :sku,
      :quantity,
      :unit_price_cents,
      :line_total_cents
    ])
    |> validate_required([
      :order_id,
      :sku,
      :quantity,
      :unit_price_cents,
      :line_total_cents
    ])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:unit_price, greater_than_or_equal_to: 0)
    |> validate_number(:line_total_cents, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:order_id)
  end
end
