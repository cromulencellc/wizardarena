defmodule Teaminterface.ProofFeedbackController do
  use Teaminterface.Web, :controller
  import Ecto.Query

  alias Teaminterface.ProofFeedback

  plug :scrub_params, "proof_feedback" when action in [:create, :update]

  def index(conn, params) do
    q = ProofFeedback
    |> join(:inner, [pf], p in assoc(pf, :proof))
    |> join(:inner, [pf, p], t in assoc(pf, :team))
    |> join(:inner, [pf, p, t], v in assoc(pf, :target))
    |> join(:inner, [pf, p, t, v], cs in assoc(pf, :challenge_set))
    |> order_by([pf, p, t, v, cs], [desc: pf.id])
    |> preload([pf, p, t, v, cs], [proof: p,
                                   team: t,
                                   target: v,
                                   challenge_set: cs])

    q = cond do
      proof_id = Map.get(params, "proof_id", false) ->
        q |> where([pf, p, t, v, cs], p.id == ^proof_id)
      not_proof_id = Map.get(params, "not_proof_id", false) ->
        q |> where([pf, p, t, v, cs], p.id != ^not_proof_id)
      true -> q
    end

    q = cond do
      digest = Map.get(params, "digest", false) ->
        q |> where([pf, p, t, v, cs], p.digest == ^digest)
      not_digest = Map.get(params, "not_digest", false) ->
        q |> where([pf, p, t, v, cs], p.digest != ^not_digest)
      true -> q
    end

    q = cond do
      team_id = Map.get(params, "team_id", false) ->
        q |> where([pf, p, t, v, cs], t.id == ^team_id)
      not_team_id = Map.get(params, "not_team_id", false) ->
        q |> where([pf, p, t, v, cs], t.id != ^not_team_id)
      true -> q
    end

    q = cond do
      target_id = Map.get(params, "target_id", false) ->
        q |> where([pf, p, t, v, cs], v.id == ^target_id)
      not_target_id = Map.get(params, "not_target_id", false) ->
        q |> where([pf, p, t, v, cs], v.id != ^not_target_id)
      true -> q
    end

    q = cond do
      cset_id = Map.get(params, "challenge_set_id", false) ->
        q |> where([pf, p, t, v, cs], cs.id == ^cset_id)
      not_cset_id = Map.get(params, "not_challenge_set_id", false) ->
        q |> where([pf, p, t, v, cs], cs.id != ^not_cset_id)
      true -> q
    end

    q = cond do
      successful = Map.get(params, "successful", false) ->
        q |> where([pf, p, t, v, cs], pf.successful == ^successful)
      true -> q
    end

    symbolized_params = params
    |> Enum.map(fn({key, value}) -> {String.to_atom(key), value} end)

    proof_feedbacks = Repo.paginate q, params

    render(conn, "index.html", title: "proof fedbacks",
           proof_feedbacks: proof_feedbacks.entries,
           pagination: proof_feedbacks,
           symbolized_params: symbolized_params)
  end

  def new(conn, _params) do
    changeset = ProofFeedback.changeset(%ProofFeedback{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"proof_feedback" => proof_feedback_params}) do
    changeset = ProofFeedback.changeset(%ProofFeedback{}, proof_feedback_params)

    case Repo.insert(changeset) do
      {:ok, _proof_feedback} ->
        conn
        |> put_flash(:info, "Proof feedback created successfully.")
        |> redirect(to: proof_feedback_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    proof_feedback = Repo.get!(ProofFeedback, id)
    render(conn, "show.html", proof_feedback: proof_feedback)
  end

  def edit(conn, %{"id" => id}) do
    proof_feedback = Repo.get!(ProofFeedback, id)
    changeset = ProofFeedback.changeset(proof_feedback)
    render(conn, "edit.html", proof_feedback: proof_feedback, changeset: changeset)
  end

  def update(conn, %{"id" => id, "proof_feedback" => proof_feedback_params}) do
    proof_feedback = Repo.get!(ProofFeedback, id)
    changeset = ProofFeedback.changeset(proof_feedback, proof_feedback_params)

    case Repo.update(changeset) do
      {:ok, proof_feedback} ->
        conn
        |> put_flash(:info, "Proof feedback updated successfully.")
        |> redirect(to: proof_feedback_path(conn, :show, proof_feedback))
      {:error, changeset} ->
        render(conn, "edit.html", proof_feedback: proof_feedback, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    proof_feedback = Repo.get!(ProofFeedback, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(proof_feedback)

    conn
    |> put_flash(:info, "Proof feedback deleted successfully.")
    |> redirect(to: proof_feedback_path(conn, :index))
  end
end
