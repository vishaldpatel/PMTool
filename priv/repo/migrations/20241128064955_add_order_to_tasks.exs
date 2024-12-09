defmodule PmTool.Repo.Migrations.AddOrderToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :task_order, :integer, null: false
    end

    create index(
             :tasks,
             [
               :creator_id,
               :team_id,
               :stage,
               :task_order
             ]
           )
  end
end
