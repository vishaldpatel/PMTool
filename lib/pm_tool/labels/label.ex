defmodule PmTool.Labels.Label do
  use Ecto.Schema
  import Ecto.Changeset

  @label_types ["project", "task"]
  def label_types, do: @label_types

  schema "labels" do
    field :name, :string
    field :color, :string
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(label, attrs) do
    label
    |> cast(attrs, [:name, :color, :type])
    |> validate_required([:name, :color, :type])
    |> validate_inclusion(:type, @label_types)
    |> unique_constraint([:name, :type], name: :labels_name_type_index)
  end
end
