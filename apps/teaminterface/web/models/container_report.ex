defmodule Teaminterface.ContainerReport do
  use Teaminterface.Web, :model

  schema "container_reports" do
    field :replay_seed, :string
    field :polls_passed, :integer
    field :polls_failed, :integer
    field :polls_timed_out, :integer
    field :polls_total, :integer
    field :last_complete_position, :integer
    field :max_position, :integer
    belongs_to :team, Teaminterface.Team
    belongs_to :round, Teaminterface.Round
    belongs_to :challenge_set, Teaminterface.ChallengeSet

    timestamps
  end

  @required_fields ~w(replay_seed polls_passed polls_failed polls_timed_out polls_total last_complete_position max_position)
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
