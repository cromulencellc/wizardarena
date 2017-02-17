defmodule Teaminterface.PollFeedback do
  use Teaminterface.Web, :model

  import Ecto.Query, only: [from: 2]

  alias Teaminterface.ChallengeSet
  alias Teaminterface.Poller
  alias Teaminterface.PollFeedback
  alias Teaminterface.Round
  alias Teaminterface.Team

  alias Teaminterface.Repo

  schema "poll_feedbacks" do
    field :wall_time, :float
    field :max_rss, :integer
    field :min_flt, :integer
    field :utime, :float
    field :task_clock, :integer
    field :cpu_clock, :integer
    field :status, :string
    belongs_to :team, Teaminterface.Team
    belongs_to :poller, Teaminterface.Poller

    has_one :challenge_set, through: [:poller, :challenge_set]
    timestamps
  end

  @required_fields ~w(wall_time max_rss min_flt utime task_clock cpu_clock status)
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

  def for_team_in_round(_team = %Teaminterface.Team{id: team_id}, round) do
    for_team_in_round(team_id, round)
  end

  def for_team_in_round(team_id, round_id) do
    poller_ids = from(p in Poller,
                   where: (p.round_id == ^round_id),
                   select: p.id)
    |> Repo.all

    from(p in PollFeedback,
         where: ((p.team_id == ^team_id) and
                 (p.poller_id in ^poller_ids)),
         preload: :challenge_set)
    |> Repo.all
  end

  def as_feedback_json(feedback) do
    cset = case assoc_loaded?(feedback.challenge_set) do
             true -> feedback.challenge_set
             false ->
               feedback |> assoc(:challenge_set) |> Repo.one
           end

    %{"csid" => (cset.id |> Integer.to_string)}
  end

  def feedback_aggregate(_team = %Team{id: team_id},
                         cset = %ChallengeSet{id: cset_id}) do
    base = from(pf in PollFeedback,
                join: p in Poller, on: pf.poller_id == p.id,
                where: ((p.challenge_set_id == ^cset_id) and
                (pf.team_id == ^team_id)),
                order_by: [desc: p.round_id])

    counts = from([pf, p] in base,
                  group_by: [p.round_id, pf.status],
                  select: {p.round_id, pf.status, count(pf.status)})
    |> Repo.all
    |> Enum.map(fn({round_id, status, count}) ->
      {round_id, tuneup_status(status), count}
    end)
    |> Enum.reduce(%{}, fn({round_id, status, count}, running) ->
      changed = running
      |> Map.get(round_id, %{})
      |> Map.put(status, count)

      Map.put(running, round_id, changed)
    end)


    averages = from([pf, p] in base,
                    group_by: [p.round_id],
                    select: {p.round_id,
                             fragment("? / ?",
                                       avg(pf.wall_time),
                                       avg(p.mean_wall_time)),
                              fragment("? / ?",
                                       avg(pf.max_rss),
                                       avg(p.mean_max_rss))})
    |> Repo.all

    averages
    |> Enum.map(fn({round_id, time, memory}) ->
      %{"round_id" => round_id,
        "functionality" => Map.get(counts, round_id),
        "performance" => %{"time" => time,
                           "memory" => memory}}
    end)
  end

  def aggregate_feedback_statuses(team_id, round_id) do
    base = from(pf in PollFeedback,
                join: p in Poller, on: pf.poller_id == p.id,
                join: cs in ChallengeSet, on: p.challenge_set_id == cs.id,
                where: ((p.round_id == ^round_id) and
                (pf.team_id == ^team_id)))

    counts = from([pf, p, cs] in base,
                  group_by: [cs.id,
                             pf.status],
                  select: {cs.id,
                           pf.status,
                           count(pf.status)})
    |> Repo.all
    |> Enum.map(fn({id, status_name, count}) ->
      {id, tuneup_status(status_name), count}
    end)

    averages = from([pf, p, cs] in base,
                    group_by: [cs.id],
                    select:  {cs.id,
                              fragment("? / ?",
                                       avg(pf.wall_time),
                                       avg(p.mean_wall_time)),
                              fragment("? / ?",
                                       avg(pf.max_rss),
                                       avg(p.mean_max_rss))})
    |> Repo.all

    count_map = counts
    |> Enum.reduce(%{
          "success" => 0,
          "timeout" => 0,
          "connect" => 0,
          "function" => 0
               }, fn({id, status, count}, running) ->
      changed = running
      |> Map.get(id, %{})
      |> Map.put(status, count)

      Map.put(running, id, changed)
    end)

    averages
    |> Enum.map(fn({id, time, memory}) ->
      %{"csid" => (id |> Integer.to_string) ,
        "functionality" => Map.get(count_map, id),
        "performance" => %{"time" => time,
                           "memory" => memory}}
    end)
  end

  defp tuneup_status("functionality") do
    "function"
  end

  defp tuneup_status(status) do
    status
  end
end
