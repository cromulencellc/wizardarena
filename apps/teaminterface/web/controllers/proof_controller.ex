defmodule Teaminterface.ProofController do
  use Teaminterface.Web, :controller
  import Ecto.Query

  alias Teaminterface.Proof
  alias Teaminterface.ProofFeedback

  plug :scrub_params, "proof" when action in [:create, :update]

  def index(conn, params) do
    q = Proof
    |> join(:inner, [p], t in assoc(p, :team))
    |> join(:inner, [p, t], v in assoc(p, :target))
    |> join(:inner, [p, t, v], cs in assoc(p, :challenge_set))
    |> order_by([p, t, v, cs], [desc: p.id])
    |> preload([p, t, v, cs], [team: t,
                               target: v,
                               challenge_set: cs])

    q = cond do
      team_id = Map.get(params, "team_id", false) ->
        q |> where([p, t, v, cs], t.id == ^team_id)
      not_team_id = Map.get(params, "not_team_id", false) ->
        q |> where([p, t, v, cs], t.id != ^not_team_id)
      true -> q
    end

    q = cond do
      cset_id = Map.get(params, "challenge_set_id", false) ->
        q |> where([p, t, v, cs], cs.id == ^cset_id)
      not_cset_id = Map.get(params, "not_challenge_set_id", false) ->
        q |> where([p, t, v, cs], cs.id != ^not_cset_id)
      true -> q
    end

    q = cond do
      target_id = Map.get(params, "target_id", false) ->
        q |> where([p, t, v, cs], v.id == ^target_id)
      not_target_id = Map.get(params, "not_target_id", false) ->
        q |> where([p, t, v, cs], v.id != ^not_target_id)
      true -> q
    end

    q = cond do
      digest = Map.get(params, "digest", false) ->
        q |> where([p, t, v, cs], p.digest == ^digest)
      not_digest = Map.get(params, "not_digest", false) ->
        q |> where([p, t, v, cs], p.digest != ^not_digest)
      true -> q
    end

    proofs = q
    |> Repo.paginate(params)

    symbolized_params = params
    |> Enum.map(fn({key, value}) -> {String.to_atom(key), value} end)

    render(conn, "index.html", title: "proofs",
           proofs: proofs.entries,
           pagination: proofs,
           symbolized_params: symbolized_params)
  end

  def show(conn, %{"id" => id}) do
    proof = Proof
    |> where([p], p.id == ^id)
    |> join(:inner, [p], t in assoc(p, :team))
    |> join(:inner, [p, t], v in assoc(p, :target))
    |> join(:inner, [p, t, v], cs in assoc(p, :challenge_set))
    |> preload([p, t, v, cs], [team: t,
                               target: v,
                               challenge_set: cs])
    |> Repo.one

    feedback_count = ProofFeedback
    |> where([pf], pf.proof_id == ^proof.id)
    |> select([pf], count(pf.id))
    |> Repo.one

    render(conn, "show.html", title: "proof #{proof.id}",
           proof: proof,
           feedback_count: feedback_count
    )
  end
end
