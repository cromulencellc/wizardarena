defmodule Teaminterface.DashboardController do
  use Teaminterface.Web, :controller

  import Ecto.Query, only: [from: 2]

  alias Teaminterface.DownloadUtils
  alias Teaminterface.Repo

  alias Teaminterface.ChallengeBinary
  alias Teaminterface.ChallengeSet
  alias Teaminterface.Enablement
  alias Teaminterface.Firewall
  alias Teaminterface.Proof
  alias Teaminterface.Replacement
  alias Teaminterface.Round
  alias Teaminterface.Team

  def index(conn, _params) do
    team = conn.assigns[:authed_team]
    [current_round | recent_rounds] = Round.recent
    csets = Round.challenge_sets(current_round)

    render(conn, "index.html", title: "Team Dashboard",
           team: team,
           current_round: current_round,
           recent_rounds: recent_rounds,
           csets: csets)
  end

  def scoreboard(conn, _params) do
    scores = Team.human_scoreboard

    render(conn, "scoreboard.html", title: "Scoreboard",
           scores: scores)
  end

  def team(conn, _params = %{"id" => team_id}) do
    team(conn, Repo.get(Team, team_id))
  end

  def team(conn, nil) do
    conn |> not_found
  end

  def team(conn, team = %Team{}) do
    render(conn, "team.html", title: team.shortname,
           team: team)
  end

  def rounds(conn, _params) do
    rounds = Round.all_past_rounds

    render(conn, "rounds.html", title: "All rounds",
           rounds: rounds)
  end

  def round(conn, _params = %{"id" => round_id}) do
    round = try do
              Repo.get Round, round_id
            rescue
              _ -> conn |> not_found
            else
              rnd -> rnd
            end

    round(conn, round)
  end

  def round(conn, nil) do
    conn |> not_found
  end

  def round(conn, _round = %Round{id: 0}) do
    current_round = Round.current_or_prev
    team = conn.assigns[:authed_team]

    csets = from(cs in Ecto.assoc(current_round, :challenge_sets),
                 preload: [:challenge_binaries, :firewalls, :replacements])
    |> Repo.all

    render(conn, "round_zero.html", title: "Round zero",
           challenge_sets: csets,
           team: team)
  end

  def round(conn, _round = %Round{started_at: nil}) do
    conn |> not_found
  end

  def round(conn, round = %Round{}) do
    team = conn.assigns[:authed_team]
    replacements = Replacement.in_round_for_team(round, team)

    firewalls = Firewall.in_round_for_team(round, team)

    crashes = Teaminterface.Crash.for_team_in_round(team.id, round.id)

    proof_feedbacks = Teaminterface.ProofFeedback.
    for_team_in_round(team.id, round.id)

    poll_feedbacks = Teaminterface.PollFeedback.
    aggregate_feedback_statuses(team.id, round.id)

    render(conn, "round.html", title: "Round #{round.id}",
           round: round,
           replacements: replacements,
           firewalls: firewalls,
           proof_feedbacks: proof_feedbacks,
           poll_feedbacks: poll_feedbacks,
           crashes: crashes
    )
  end

  def challenge_binary(conn, _params = %{"cbid" => cbid}) do
    cb = ChallengeBinary.find_enabled_by_filename(cbid)
    challenge_binary(conn, cb)
  end

  def challenge_binary(conn, nil) do
    conn |> not_found
  end

  def challenge_binary(conn, cb = %ChallengeBinary{}) do
    cset = Ecto.assoc(cb, :challenge_set) |> Repo.one

    versions = cb
    |> Ecto.assoc(:replacements)
    |> Ecto.Query.order_by(desc: :inserted_at, desc: :id)
    |> Ecto.Query.preload(:team)
    |> Repo.all

    cbid = ChallengeBinary.cbid cb, cset

    render(conn, "challenge_binary.html", title: "Challenge Binary #{cbid}",
           cb: cb,
           cset: cset,
           versions: versions)
  end

  def challenge_set(conn, _params = %{"csid" => csid}) do
    challenge_set(conn, ChallengeSet.get_enabled_by_csid(csid))
  end

  def challenge_set(conn, nil) do
    conn |> not_found
  end

  def challenge_set(conn, cset = %ChallengeSet{}) do
    team = conn.assigns[:authed_team]

    firewalls = Firewall.live_for_cset(cset)
    pending_firewall = Firewall.pending(team, cset)

    povs = Proof.live_for_team_and_cset(team, cset)

    binaries = cset
    |> Ecto.assoc(:challenge_binaries)
    |> Ecto.Query.order_by(asc: :index)
    |> Repo.all

    teams = Team.picker

    render(conn, "challenge_set.html", title: "cset #{cset.shortname}",
           cset: cset,
           binaries: binaries,
           povs: povs,
           pending_firewall: pending_firewall,
           firewalls: firewalls,
           teams: teams)
  end

  def proof_feedbacks(conn, params = %{"csid" => csid}) do
    team = conn.assigns[:authed_team]
    page = Map.get(params, "page", 1)
    cset = ChallengeSet.get_enabled_by_csid(csid)

    %{count: count, feedbacks: feedbacks} =
      Teaminterface.ProofFeedback.paginated(team, cset, page)

    render(conn, "proof_feedbacks.html", title: "pov feedback #{csid}",
           cset: cset,
           feedbacks: feedbacks,
           count: count)
  end

  def poll_feedbacks(conn, _params = %{"csid" => csid}) do
    team = conn.assigns[:authed_team]

    cset = ChallengeSet.get_enabled_by_csid(csid)

    agg = Teaminterface.PollFeedback.feedback_aggregate(team, cset)

    render(conn, "poll_feedback.html", title: "poll feedback #{csid}",
           cset: cset,
           feedback: agg)
  end

  def cb_feedbacks(conn, params = %{"csid" => csid}) do
    team = conn.assigns[:authed_team]
    page = Map.get(params, "page", 1)
    cset = ChallengeSet.get_enabled_by_csid(csid)

    %{count: count,
      crashes: crashes} = Teaminterface.Crash.paginated(team, cset, page)

    render(conn, "cb_feedbacks.html", title: "CB feedback #{csid}",
           cset: cset,
           count: count,
           crashes: crashes)
  end

  def firewall(conn, _params = %{"id" => firewall_id}) do
    case Integer.parse(firewall_id) do
      :error -> conn |> not_found
      {fw_id, _rest} ->
        firewall(conn, fw_id)
    end
  end

  def firewall(conn, firewall_id) do
    round = Round.current_or_prev

    firewall = Firewall.get_for_team_in_round(firewall_id,
                                              conn.assigns[:authed_team],
                                              round)
    cset = Ecto.assoc(firewall, :challenge_set) |> Repo.one
    team = Ecto.assoc(firewall, :team) |> Repo.one

    similar = Firewall.similar_with_round(firewall,
                                          round)

    render(conn, "firewall.html",
           title: "Firewall #{firewall.id}",
           firewall: firewall,
           cset: cset,
           team: team,
           similar: similar)
  end

  def get_ids(conn, _params = %{"id" => firewall_id}) do
    team = conn.assigns[:authed_team]
    round = Round.current_or_prev

    case Integer.parse(firewall_id) do
      :error -> conn |> not_found
      {fw_id, _rest} ->
        firewall = Firewall.get_for_team_in_round(fw_id,
                                                  team,
                                                  round)

        serve_ids(conn, firewall)
    end
  end

  defp serve_ids(conn, firewall = %Firewall{}) do
    ids_id = [firewall.challenge_set.shortname,
              firewall.digest,
              firewall.inserted_at |> DateTime.to_unix]
    |> Enum.join("_")

    DownloadUtils.serve(conn,
                        firewall,
                        ids_id)
  end

  defp serve_ids(conn, _other) do
    conn |> not_found
  end


  def replace_ids(conn, _params = %{"csid" => csid,
                                    "firewall" => %{"ids" => ids_file}}) do
    team = conn.assigns[:authed_team]
    enablement = Teaminterface.UploadUtils.get_enablement_for_cset(csid)

    validity = Teaminterface.Ids.upload(enablement,
                                        team,
                                        ids_file)

    case validity do
      %{error: error_messages} ->
        mesg = "IDS upload error: #{error_messages}"
        conn
        |> put_flash(:error, mesg)
        |> redirect(to: dashboard_path(conn,
                                       :challenge_set,
                                       csid))
      %{round: round_id, hash: digest, file: _fname} ->
        inserted = Repo.get_by!(Firewall,
                                round_id: round_id,
                                digest: digest,
                                team_id: team.id,
                                challenge_set_id: enablement.challenge_set_id)
        redirect(conn, to: dashboard_path(conn, :firewall, inserted.id))
    end
  end

  def replacement(conn, _params = %{"id" => id}) do
    round = Round.current_or_prev

    replacement = Replacement.get_for_team_in_round(id,
                                                    conn.assigns[:authed_team],
                                                    round)

    cb = Ecto.assoc(replacement, :challenge_binary) |> Repo.one
    cset = Ecto.assoc(cb, :challenge_set) |> Repo.one
    team = Ecto.assoc(replacement, :team) |> Repo.one

    similar = Replacement.similar_with_round(replacement,
                                             round)

    render(conn, "replacement.html",
           title: "Replacement #{replacement.id}",
           replacement: replacement,
           cb: cb,
           cset: cset,
           team: team,
           similar: similar)
  end

  def get_rcb(conn, _params = %{"id" => rcb_id}) do
    team = conn.assigns[:authed_team]
    round = Round.current_or_prev

    rep = Replacement.get_for_team_in_round(rcb_id,
                                            team,
                                            round)

    serve_rcb(conn, rep)
  end

  defp serve_rcb(conn, nil) do
    conn |> not_found
  end

  defp serve_rcb(conn, rep = %Replacement{}) do
    cbid = rep.challenge_binary
    |> ChallengeBinary.cbid

    rep_filename = [cbid,
              rep.digest,
              rep.inserted_at |> DateTime.to_unix]
    |> Enum.join("_")

    DownloadUtils.serve(conn,
                        %{rep |
                          round: rep |> Ecto.assoc(:round) |> Repo.one},
                        rep_filename)
  end

  def replace_rcb(conn, _params = %{"cbid" => cbid,
                                    "replacement" => %{"rcb" => rcb_file}}) do
    team = conn.assigns[:authed_team]
    cb = ChallengeBinary.find_by_filename(cbid)
    enablement = Enablement.current_for_cb(cb)

    validity = Teaminterface.Rcb.upload(cbid,
                                        rcb_file,
                                        team,
                                        enablement)

    case validity do
      %{error: error_messages} ->
        mesg = "RCB upload error: #{error_messages}"
        conn
        |> put_flash(:error, mesg)
        |> redirect(to: dashboard_path(conn,
                                       :challenge_binary,
                                       cbid))
      %{valid: "no"} ->
        conn
        |> put_flash(:error, "RCB upload error")
        |> redirect(to: dashboard_path(conn,
                                       :challenge_binary,
                                       cbid))
      %{valid: "yes", file: ^cbid} ->
        inserted = Repo.get_by!(Replacement,
                                round_id: enablement.round_id,
                                team_id: team.id,
                                challenge_binary_id: cb.id)
        redirect(conn, to: dashboard_path(conn, :replacement, inserted.id))
    end
  end

  def replace_pov(conn, params) do
    replace_pov_with_round(conn,
                           Round.current,
                           params)
  end

  defp replace_pov_with_round(conn, nil, _params) do
    conn |> send_resp(400, "No current round")
  end

  defp replace_pov_with_round(conn,
                              _round,
                              _params = %{"proof" => %{
                                           "csid" => csid,
                                           "target_id" => target_id,
                                           "throws" => throws,
                                           "pov" => pov_file}}) do
    team = conn.assigns[:authed_team]
    target = Repo.get!(Team, target_id)
    cs = Repo.get_by!(ChallengeSet, shortname: csid)
    round = Round.current
    enablement = Repo.get_by!(Enablement,
                              challenge_set_id: cs.id,
                              round_id: round.id)

    validity = Teaminterface.Pov.upload(enablement,
                                        team,
                                        target,
                                        throws |> String.to_integer,
                                        pov_file)

    case validity do
      %{error: error_messages} ->
        mesg = "POV upload error: #{error_messages}"
        conn
        |> put_flash(:error, mesg)
        |> redirect(to: dashboard_path(conn,
                                       :challenge_set,
                                       csid))
      %{round: round_id, hash: digest} ->
        inserted = Repo.get_by!(Proof,
                                round_id: round_id,
                                digest: digest,
                                team_id: team.id,
                                target_id: target.id,
                                challenge_set_id: cs.id)
        redirect(conn, to: dashboard_path(conn,
                                          :proof,
                                          inserted.id))
    end
  end

  defp replace_pov_with_round(conn, _round, _params) do
    conn
    |> put_flash(:error, "POV upload error: malformed request")
    |> redirect(to: dashboard_path(conn, :index))
  end

  def proof(conn, _params = %{"id" => proof_id}) do
    proof = Repo.get_by!(Proof,
                         id: proof_id,
                         team_id: conn.assigns[:authed_team].id)

    target = Ecto.assoc(proof, :target) |> Repo.one
    cset = Ecto.assoc(proof, :challenge_set) |> Repo.one

    feedbacks = Ecto.assoc(proof, :proof_feedbacks) |> Repo.all

    render(conn, "proof.html",
           title: "Proof #{proof.id}",
           proof: proof,
           target: target,
           cset: cset,
           feedbacks: feedbacks)
  end

  defp not_found(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> put_resp_header("content-disposition", "inline")
    |> send_resp(404, "not found")
  end
end
