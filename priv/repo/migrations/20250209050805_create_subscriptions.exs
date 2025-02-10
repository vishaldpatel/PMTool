defmodule PmTool.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :stripe_id, :string
      add :stripe_customer_id, :string
      add :plan, :string
      add :status, :string
      add :current_period_started_at, :utc_datetime
      add :current_period_ends_at, :utc_datetime
      add :cancel_at_period_end, :boolean

      timestamps()
    end

    create unique_index(:subscriptions, [:stripe_id])
    create index(:subscriptions, [:stripe_customer_id])
  end
end
