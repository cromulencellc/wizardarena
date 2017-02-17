defmodule Teaminterface.ReplacementController do
  use Teaminterface.Web, :controller
  import Ecto.Query

  alias Teaminterface.Replacement

  plug :scrub_params, "replacement" when action in [:create, :update]

  def index(conn, params) do
    q = Replacement
    |> join(:inner, [rcb], t in assoc(rcb, :team))
    |> join(:inner, [rcb, t], cb in assoc(rcb, :challenge_binary))
    |> join(:inner, [rcb, t, cb], cs in assoc(cb, :challenge_set))
    |> order_by([rcb, t, cb, cs], [desc: rcb.id])
    |> preload([rcb, t, cb, cs], [team: t,
                                 challenge_binary: cb,
                                 challenge_set: cs])

    q = cond do
      team_id = Map.get(params, "team_id", false) ->
        q |> where([rcb, t, cb, cs], t.id == ^team_id)
      not_team_id = Map.get(params, "not_team_id", false) ->
        q |> where([rcb, t, cb, cs], t.id != ^not_team_id)
      true -> q
    end

    q = cond do
      round_id = Map.get(params, "round_id", false) ->
        q |> where([rcb, t, cb, cs], rcb.round_id == ^round_id)
      not_round_id = Map.get(params, "not_round_id", false) ->
        q |> where([rcb, t, cb, cs], rcb.round_id != ^not_round_id)
      true -> q
    end

    q = cond do
      challenge_set_id = Map.get(params, "challenge_set_id", false) ->
        q |> where([rcb, t, cb, cs], cs.id == ^challenge_set_id)
      not_challenge_set_id = Map.get(params, "not_challenge_set_id", false) ->
        q |> where([rcb, t, cb, cs], cs.id != ^not_challenge_set_id)
      true -> q
    end

    q = cond do
      challenge_binary_id = Map.get(params, "challenge_binary_id", false) ->
        q |> where([rcb, t, cb, cs], cb.id == ^challenge_binary_id)
      not_challenge_binary_id = Map.get(params, "not_challenge_binary_id", false) ->
        q |> where([rcb, t, cb, cs], cb.id != ^not_challenge_binary_id)
      true -> q
    end

    q = cond do
      size_gt = Map.get(params, "size_gt", false) ->
        q |> where([rcb, t, cb, cs], rcb.size > ^size_gt)
      true -> q
    end

    q = cond do
      size_lt = Map.get(params, "size_lt", false) ->
        q |> where([rcb, t, cb, cs], rcb.size < ^size_lt)
      true -> q
    end

    q = cond do
      digest = Map.get(params, "digest", false) ->
        q |> where([rcb, t, cb, cs], rcb.digest == ^digest)
      not_digest = Map.get(params, "not_digest", false) ->
        q |> where([rcb, t, cb, cs], rcb.digest != ^not_digest)
      true -> q
    end

    replacements = q
    |> Repo.paginate(params)

    symbolized_params = params
    |> Enum.map(fn({key, value}) -> {String.to_atom(key), value} end)

    render(conn, "index.html", title: "replacemebnts",
           replacements: replacements.entries,
           pagination: replacements,
           symbolized_params: symbolized_params)
  end

  def show(conn, %{"id" => id}) do
    replacement = Repo.get!(Replacement, id)
    render(conn, "show.html", replacement: replacement)
  end
end
