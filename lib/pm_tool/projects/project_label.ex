defmodule PmTool.Projects.ProjectLabel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "project_labels" do
    belongs_to :project, PmTool.Projects.Project
    belongs_to :label, PmTool.Labels.Label

    timestamps()
  end

  @doc false
  def changeset(project_label, attrs) do
    project_label
    |> cast(attrs, [:project_id, :label_id])
    |> validate_required([:project_id, :label_id])
    |> unique_constraint([:project_id, :label_id], name: :project_labels_project_id_label_id_index)
  end
end
