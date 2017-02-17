defmodule Teaminterface.Router do
  use Teaminterface.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Teaminterface.EitherAuth
  end

  pipeline :admin do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_layout, {Teaminterface.LayoutView, :admin}
    plug Teaminterface.AdminAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Teaminterface.BasicAuth
  end

  scope "/", Teaminterface do
    pipe_through :api # Use the default browser stack

    get "/", PageController, :index # safety valve to go to dashboard

    # re.compile("^/status$"): 'application/json',  # Game status
    get "/status", StatusController, :index

    # re.compile("^/round/[0-9]+/feedback/cb$"): 'application/json', # CB Stats
    get "/round/:round_id/feedback/cb",
        FeedbackController, :cb, as: :feedback_cb
    # re.compile("^/round/[0-9]+/feedback/pov$"): 'application/json',  # POV Status
    get "/round/:round_id/feedback/pov",
        FeedbackController, :pov, as: :feedback_pov
    # re.compile("^/round/[0-9]+/feedback/poll$"): 'application/json',  # Poll status
    get "/round/:round_id/feedback/poll",
        FeedbackController, :poll, as: :feedback_poll

    # re.compile("^/round/[0-9]+/evaluation/cb/[1-7]$"): 'application/json',  # Other team's reformulated CB status
    get "/round/:round_id/evaluation/cb/:team_id",
        EvaluationController, :cb, as: :evaluation_cb
    # re.compile("^/round/[0-9]+/evaluation/ids/[1-7]$"): 'application/json',  # Other team's IDS status
    get "/round/:round_id/evaluation/ids/:team_id",
        EvaluationController, :ids, as: :evaluation_ids

    # re.compile("^/dl/[1-7]/cb/[0-9a-zA-Z_]+$"): 'application/octet-stream',  # Reforumated CB downloads
    get "/dl/:team_id/cb/:cb_id", DownloadController, :cb, as: :download_cb
    # re.compile("^/dl/[1-7]/ids/[0-9a-zA-Z_]+\\.ids$"): 'text/plain'}  # IDS Rule downloads
    get "/dl/:team_id/ids/:ids_id", DownloadController, :ids, as: :download_ids

    post "/rcb", RcbUploadController, :rcb, as: :upload_rcb
    post "/ids", IdsUploadController, :ids, as: :upload_ids
    post "/pov", PovUploadController, :pov, as: :upload_pov
  end

  scope "/u", Teaminterface do
    pipe_through :browser

    get "/", DashboardController, :index
    get "/scoreboard", DashboardController, :scoreboard
    get "/round/:id", DashboardController, :round
    get "/rounds", DashboardController, :rounds

    get "/cset/:csid", DashboardController, :challenge_set
    get "/cset/:csid/proof_feedbacks", DashboardController, :proof_feedbacks
    get "/cset/:csid/poll_feedbacks", DashboardController, :poll_feedbacks
    get "/cset/:csid/cb_feedbacks", DashboardController, :cb_feedbacks

    get "/cb/:cbid", DashboardController, :challenge_binary
    get "/replacement/:id", DashboardController, :replacement
    get "/firewall/:id", DashboardController, :firewall
    get "/team/:id", DashboardController, :team
    get "/pov/:id", DashboardController, :proof

    get "/firewall/:id/dl", DashboardController, :get_ids
    post "/cset/:csid/firewall", DashboardController, :replace_ids

    post "/pov", DashboardController, :replace_pov

    get "/replacement/:id/dl", DashboardController, :get_rcb
    post "/cb/:cbid/replacement", DashboardController, :replace_rcb
  end

  scope "/admin", Teaminterface do
    pipe_through :admin

    resources "/challenge_sets", ChallengeSetController
    resources "/challenge_binaries", ChallengeBinaryController
    resources "/challenge_set_aliases", ChallengeSetAliasController
    resources "/rounds", RoundController
    resources "/enablements", EnablementController
    resources "/teams", TeamController
    resources "/replacements", ReplacementController
    resources "/firewalls", FirewallController
    resources "/proofs", ProofController
    resources "/proof_feedbacks", ProofFeedbackController
    resources "/crashes", CrashController
    resources "/poll_feedbacks", PollFeedbackController
    resources "/container_reports", ContainerReportController
    resources "/pollers", PollerController
    resources "/evaluations", GeneratedEvaluationController, name: "evaluation"
    resources "/scores", ScoreController
  end

  # Other scopes may use custom stacks.
  # scope "/api", Teaminterface do
  #   pipe_through :api
  # end
end
