defmodule Teaminterface.Poller do
  use Teaminterface.Web, :model

  schema "pollers" do
    field :seed, :binary
    field :mean_wall_time, :float
    field :stddev_wall_time, :float
    field :mean_max_rss, :float
    field :stddev_max_rss, :float
    field :mean_min_flt, :float
    field :stddev_min_flt, :float
    field :mean_utime, :float
    field :stddev_utime, :float
    field :mean_task_clock, :float
    field :stddev_task_clock, :float
    field :mean_cpu_clock, :float
    field :stddev_cpu_clock, :float
    belongs_to :round, Teaminterface.Round
    belongs_to :challenge_set, Teaminterface.ChallengeSet

    timestamps
  end

  @required_fields ~w(seed mean_wall_time stddev_wall_time mean_max_rss stddev_max_rss mean_min_flt stddev_min_flt mean_utime stddev_utime mean_task_clock stddev_task_clock mean_cpu_clock stddev_cpu_clock)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(
      :seed,
      name: :pollers_challenge_set_id_round_id_seed_index
    )
  end
end
