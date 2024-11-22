defmodule PmTool.Projects.TeamProject do
  use Ecto.Schema
  import Ecto.Changeset
  import PmTool.URLs

  schema "team_projects" do
    belongs_to :team, PmTool.Teams.Team
    belongs_to :project, PmTool.Projects.Project
  end

  @doc false
  def changeset(team_project, attrs) do
    team_project
    |> cast(attrs, [:team_id, :project_id])
    |> validate_required([:team_id, :project_id])
  end
end
