defmodule Teaminterface.Evaluation do
  use Teaminterface.Web, :model

  schema "evaluations" do
    field :connect, :integer
    field :success, :integer
    field :timeout, :integer
    field :time, :integer
    field :memory, :integer
    belongs_to :team, Teaminterface.Team
    belongs_to :round, Teaminterface.Round
    belongs_to :challenge_set, Teaminterface.ChallengeSet

    timestamps
  end

  @required_fields ~w(connect success timeout time memory)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> foreign_key_constraint(:team_id)
    |> foreign_key_constraint(:round_id)
    |> foreign_key_constraint(:challenge_set_id)
    |> unique_constraint(
      :round_id,
      name: :evaluations_team_id_round_id_challenge_set_id_index
    )
  end
end
