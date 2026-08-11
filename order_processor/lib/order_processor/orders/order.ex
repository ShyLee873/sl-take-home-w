defmodule OrderProcessor.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias OrderProcessor.Orders.OrderItem

  @timestamps_opts [type: :utc_datetime]

  schema "orders" do
    field(:event_id, :string)
    field(:order_number, :string)
    field(:customer_email, :string)
    field(:total_cents, :integer)
    field(:processed_at, :utc_datetime)

    has_many(:items, OrderItem)

    timestamps()
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [
      :event_id,
      :order_number,
      :customer_email,
      :total_cents,
      :processed_at
    ])
    |> validate_required([
      :event_id,
      :order_number,
      :customer_email,
      :total_cents,
      :processed_at
    ])
    |> validate_number(:total_cents, greater_than_or_equal_to: 0)
    |> unique_constraint(:event_id)
    |> unique_constraint(:order_number)
  end
end
