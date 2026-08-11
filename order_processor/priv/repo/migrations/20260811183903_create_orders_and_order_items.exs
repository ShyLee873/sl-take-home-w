defmodule OrderProcessor.Repo.Migrations.CreateOrdersAndOrderItems do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :event_id, :string, null: false
      add :order_number, :string, null: false
      add :customer_email, :string, null: false
      add :total_cents, :integer, null: false
      add :processed_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end


    create unique_index(:orders, [:event_id])
    create unique_index(:orders, [:order_number])

    create table(:order_items) do
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :sku, :string, null: false
      add :quantity, :integer, null: false
      add :unit_price_cents, :integer, null: false
      add :line_total_cents, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:order_items, [:order_id])
  end
end
