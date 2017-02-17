defmodule Teaminterface.ChallengeSetAlias do
  use Teaminterface.Web, :model

  schema "challenge_set_aliases" do
    field :cgc_id, :integer
    belongs_to :challenge_set, Teaminterface.ChallengeSet

    timestamps
  end

  @required_fields ~w(cgc_id)
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
