defmodule Teaminterface.PollFeedbackController do
  use Teaminterface.Web, :controller
  import Ecto.Query

  alias Teaminterface.PollFeedback

  plug :scrub_params, "poll_feedback" when action in [:create, :update]

  def index(conn, params) do
    q = PollFeedback
    |> join(:inner, [pf], t in assoc(pf, :team))
    |> join(:inner, [pf, t], p in assoc(pf, :poller))
    |> join(:inner, [pf, t, p], cs in assoc(p, :challenge_set))
    |> order_by([pf, t, p, cs], [desc: pf.id])
    |> preload([pf, t, p, cs], [team: t, poller: p, challenge_set: cs])

    q = cond do
      team_id = Map.get(params, "team_id", false) ->
        q |> where([pf, t, p, cs], t.id == ^team_id)
      not_team_id = Map.get(params, "not_team_id", false) ->
        q |> where([pf, t, p, cs], t.id != ^not_team_id)
      true -> q
    end

    q = cond do
      challenge_set_id = Map.get(params, "challenge_set_id", false) ->
        q |> where([pf, t, p, cs], cs.id == ^challenge_set_id)
      not_challenge_set_id = Map.get(params, "not_challenge_set_id", false) ->
        q |> where([pf, t, p, cs], cs.id != ^not_challenge_set_id)
      true -> q
    end

    q = cond do
      include_status = Map.get(params, "status", false) ->
        q |> where([pf, t, p, cs], pf.status == ^include_status)
      exclude_status = Map.get(params, "not_status", false) ->
        q |> where([pf, t, p, cs], pf.status != ^exclude_status)
      true -> q
    end

    q = cond do
      include_poller = Map.get(params, "poller_id", false) ->
        q |> where([pf, t, p, cs], pf.poller_id == ^include_poller)
      exclude_poller = Map.get(params, "not_poller_id", false) ->
        q |> where([pf, t, p, cs], pf.poller_id != ^exclude_poller)
      true -> q
    end

    poll_feedbacks = q
    |> Repo.paginate(params)

    symbolized_params = params
    |> Enum.map(fn({key, value}) -> {String.to_atom(key), value} end)

    render(conn, "index.html", title: "poll feedbacks",
           poll_feedbacks: poll_feedbacks.entries,
           pagination: poll_feedbacks,
           symbolized_params: symbolized_params)
  end

  def new(conn, _params) do
    changeset = PollFeedback.changeset(%PollFeedback{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"poll_feedback" => poll_feedback_params}) do
    changeset = PollFeedback.changeset(%PollFeedback{}, poll_feedback_params)

    case Repo.insert(changeset) do
      {:ok, _poll_feedback} ->
        conn
        |> put_flash(:info, "Poll feedback created successfully.")
        |> redirect(to: poll_feedback_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    poll_feedback = Repo.get!(PollFeedback, id)
    render(conn, "show.html", poll_feedback: poll_feedback)
  end

  def edit(conn, %{"id" => id}) do
    poll_feedback = Repo.get!(PollFeedback, id)
    changeset = PollFeedback.changeset(poll_feedback)
    render(conn, "edit.html", poll_feedback: poll_feedback, changeset: changeset)
  end

  def update(conn, %{"id" => id, "poll_feedback" => poll_feedback_params}) do
    poll_feedback = Repo.get!(PollFeedback, id)
    changeset = PollFeedback.changeset(poll_feedback, poll_feedback_params)

    case Repo.update(changeset) do
      {:ok, poll_feedback} ->
        conn
        |> put_flash(:info, "Poll feedback updated successfully.")
        |> redirect(to: poll_feedback_path(conn, :show, poll_feedback))
      {:error, changeset} ->
        render(conn, "edit.html", poll_feedback: poll_feedback, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    poll_feedback = Repo.get!(PollFeedback, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(poll_feedback)

    conn
    |> put_flash(:info, "Poll feedback deleted successfully.")
    |> redirect(to: poll_feedback_path(conn, :index))
  end
end
