defmodule Teaminterface.FirewallController do
  use Teaminterface.Web, :controller
  import Ecto.Query

  alias Teaminterface.Firewall

  plug :scrub_params, "firewall" when action in [:create, :update]

  def index(conn, params) do
    q = Firewall
    |> join(:inner, [ids], t in assoc(ids, :team))
    |> join(:inner, [ids, t], cs in assoc(ids, :challenge_set))
    |> order_by([ids, t, cs], [desc: ids.id])
    |> preload([ids, t, cs], [team: t,
                              challenge_set: cs])

    q = cond do
      team_id = Map.get(params, "team_id", false) ->
        q |> where([ids, t, cs], t.id == ^team_id)
      not_team_id = Map.get(params, "not_team_id", false) ->
        q |> where([ids, t, cs], t.id != ^not_team_id)
      true -> q
    end

    q = cond do
      round_id = Map.get(params, "round_id", false) ->
        q |> where([ids, t, cs], ids.round_id == ^round_id)
      not_round_id = Map.get(params, "not_round_id", false) ->
        q |> where([ids, t, cs], ids.round_id != ^not_round_id)
      true -> q
    end

    q = cond do
      challenge_set_id = Map.get(params, "challenge_set_id", false) ->
        q |> where([ids, t, cs], cs.id == ^challenge_set_id)
      not_challenge_set_id = Map.get(params, "not_challenge_set_id", false) ->
        q |> where([ids, t, cs], cs.id != ^not_challenge_set_id)
      true -> q
    end

    q = cond do
      digest = Map.get(params, "digest", false) ->
        q |> where([ids, t, cs], ids.digest == ^digest)
      not_digest = Map.get(params, "not_digest", false) ->
        q |> where([ids, t, cs], ids.digest != ^not_digest)
      true -> q
    end

    pagination = q |> Repo.paginate(params)

    symbolized_params = params
    |> Enum.map(fn({key, value}) -> {String.to_atom(key), value} end)

    firewalls = pagination.entries
    render(conn, "index.html", title: "firewalls",
           firewalls: firewalls,
           pagination: pagination,
           symbolized_params: symbolized_params
    )
  end

  def show(conn, %{"id" => id}) do
    firewall = Repo.get!(Firewall, id)
    render(conn, "show.html", firewall: firewall)
  end
end
