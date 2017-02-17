defmodule Teaminterface.EnablementController do
  use Teaminterface.Web, :controller

  import Ecto.Query, only: [from: 2]

  alias Teaminterface.Enablement

  plug :scrub_params, "enablement" when action in [:create]

  def index(conn, params) do
    rounds = from(r in Teaminterface.Round,
                  order_by: [asc: r.id])
    |> Repo.all

    challenge_sets = [first_cset | rest] = Repo.all(Teaminterface.ChallengeSet)

    selected_cset = Map.get(params, "cset_id", first_cset.id)

    enablements = from(e in Enablement,
                       order_by: [asc: e.round_id, asc: e.challenge_set_id],
                       select: {{e.round_id, e.challenge_set_id}, true})
    |> Repo.all
    |> Map.new

    grid = Enum.map(rounds, fn(round) ->
      Enum.map(challenge_sets, fn(challenge_set) ->
        en = Map.get(enablements,
                     {round.id, challenge_set.id},
                     false)
        %{enabled: en, cset: challenge_set.id}
      end)
    end)

    cset_picker = challenge_sets
    |> Enum.map(fn(cs) ->
      {cs.shortname, cs.id}
    end)

    render(conn, "index.html",
           rounds: rounds,
           challenge_sets: challenge_sets,
           selected_cset: selected_cset,
           enablements: enablements,
           grid: grid,
           cset_picker: cset_picker)
  end

  def new(conn, _params) do
    changeset = Enablement.changeset(%Enablement{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"enablement" => enablement_params}) do
    changeset = Enablement.changeset(%Enablement{}, enablement_params)

    case Repo.insert(changeset) do
      {:ok, _enablement} ->
        conn
        |> put_flash(:info, "Enablement created successfully.")
        |> redirect(to: enablement_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    enablement = Repo.get!(Enablement, id)
    render(conn, "show.html", enablement: enablement)
  end

  def edit(conn, %{"id" => id}) do
    enablement = Repo.get!(Enablement, id)
    changeset = Enablement.changeset(enablement)
    render(conn, "edit.html", enablement: enablement, changeset: changeset)
  end

  def update(conn, %{"id" => "ranger",
                     "ranger" => %{"choice" => "enable",
                                   "challenge_set_id" => cset_id,
                                   "start_round" => start_round_id,
                                   "end_round" => end_round_id}}) do

    Enablement.enable_range(String.to_integer(cset_id),
                            String.to_integer(start_round_id),
                            String.to_integer(end_round_id))

    redirect(conn, to: enablement_path(conn, :index, cset_id: cset_id))
  end

  def update(conn, %{"id" => "ranger",
                     "ranger" => %{"choice" => "disable",
                                   "challenge_set_id" => cset_id,
                                   "start_round" => start_round_id,
                                   "end_round" => end_round_id}}) do

    Enablement.disable_range(String.to_integer(cset_id),
                             String.to_integer(start_round_id),
                             String.to_integer(end_round_id))

    redirect(conn, to: enablement_path(conn, :index, cset_id: cset_id))
  end

  def delete(conn, %{"id" => id}) do
    enablement = Repo.get!(Enablement, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(enablement)

    conn
    |> put_flash(:info, "Enablement deleted successfully.")
    |> redirect(to: enablement_path(conn, :index))
  end
end
