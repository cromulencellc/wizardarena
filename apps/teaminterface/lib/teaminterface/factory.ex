defmodule Teaminterface.Factory do
  use ExMachina.Ecto, repo: Teaminterface.Repo

  def round_factory do
    s = sequence(:round, &"#{&1}")
    %Teaminterface.Round{
      nickname: "exampleround-#{s}",
      seed: <<1, 2, 3, 4>>,
      secret: <<1, 2, 3, 4>>
    }
  end

  def challenge_set_factory do
    s = sequence(:challenge_set, &"#{&1}")
    %Teaminterface.ChallengeSet{
      name: "challenge set #{s}",
      shortname: "cset_#{s}"
    }
  end

  def challenge_set_alias_factory do
    %Teaminterface.ChallengeSetAlias{
      cgc_id: 2744677078,
      challenge_set: build(:challenge_set)
    }
  end

  def challenge_binary_factory do
    %Teaminterface.ChallengeBinary{
      index: 0,
      size: 85548, # LUNGE_00001
      patched_size: 85548,
      challenge_set: build(:challenge_set)
    }
  end

  def enablement_factory do
    %Teaminterface.Enablement{
      round: build(:round),
      challenge_set: build(:challenge_set)
    }
  end

  def team_factory do
    s = sequence(:team, &"#{&1}")
    %Teaminterface.Team{
      name: "Test Team #{s}",
      shortname: "test-#{s}",
      color: "#f0f",
      password_digest: # "wizard arena"
      "$2b$04$UAxma4sWhbqg3XOA2AUrj.YfZLVul4JXOR3Vn4f7qcdC.xR8jZFAK",
      score: 31337.0
    }
  end

  def replacement_factory do
    %Teaminterface.Replacement{
      digest: # test/support/fixtures/LUNGE_00001.cgc
        "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452",
      size: 85548,
      team: build(:team),
      round: build(:round),
      scoot: false,
      challenge_binary: build(:challenge_binary)
    }
  end

  def firewall_factory do
    cset = build(:challenge_set)
    %Teaminterface.Firewall{
      digest: # test/support/fixtures/LUNGE_00002.rules
        "bd5329377285e3240d36312902a5555814154b9a0d746bbc5c63bf2024081e59",
      team: build(:team),
      round: build(:round),
      scoot: false,
      challenge_set: cset
    }
  end

  def proof_factory do
    cset = build(:challenge_set)
    %Teaminterface.Proof{
      digest:
        "21f628cd70c1a30735c3f3063acaa78180fa39b61d28c7176f388752595d5452",
      team: build(:team),
      round: build(:round),
      challenge_set: cset,
      target: build(:team),
      throws: 5
    }
  end

  def crash_factory do
    %Teaminterface.Crash{
      team: build(:team),
      round: build(:round),
      challenge_binary: build(:challenge_binary),
      timestamp: Timex.now
    }
  end

  def evaluation_factory do
    %Teaminterface.Evaluation{
      team: build(:team),
      round: build(:round),
      challenge_set: build(:challenge_set),
      connect: 33,
      success: 34,
      timeout: 33,
      time: 100,
      memory: 100
    }
  end

  def poller_factory do
    %Teaminterface.Poller{
      mean_wall_time: 1.0,
      round: build(:round),
      challenge_set: build(:challenge_set)
    }
  end

  def proof_feedback_factory do
    %Teaminterface.ProofFeedback{
      throw: 1,
      successful: true,
      proof: build(:proof),
      round: build(:round)
    }
  end

  def poll_feedback_factory do
    %Teaminterface.PollFeedback{
      wall_time: 1.0,
      max_rss: 1,
      min_flt: 1,
      utime: 1.0,
      task_clock: 1,
      cpu_clock: 1,
      status: "x",
      team: build(:team),
      poller: build(:poller)
    }
  end

  def make_current(round = %Teaminterface.Round{}) do
    two_minutes_ago = Timex.now
    |> Timex.shift(minutes: -2)

    %{round | started_at: two_minutes_ago}
  end

  def make_over(round = %Teaminterface.Round{}) do
    now = Timex.now
    ten_minutes_ago = now |> Timex.shift(minutes: -10)
    three_minutes_ago = now |> Timex.shift(minutes: -3)

    %{round | started_at: ten_minutes_ago, finished_at: three_minutes_ago}
  end
end
