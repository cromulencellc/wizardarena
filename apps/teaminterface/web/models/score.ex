defmodule Teaminterface.Score do
  use Teaminterface.Web, :model

  schema "scores" do
    field :security, :integer
    field :availability, :float
    field :evaluation, :float
    field :performance, :float
    field :functionality, :float
    belongs_to :team, Teaminterface.Team
    belongs_to :round, Teaminterface.Round

    timestamps
  end

  @required_fields ~w(security availability evaluation)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
