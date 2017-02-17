defmodule Teaminterface.DashboardView do
  use Teaminterface.Web, :view

  alias Teaminterface.ChallengeBinary
  alias Teaminterface.ChallengeSet
  alias Teaminterface.Firewall
  alias Teaminterface.Replacement
  alias Teaminterface.Team

  def score(_team = %Team{score: numeric_score}) do
    score(numeric_score)
  end

  def score(numeric_score) when is_float(numeric_score) do
    (numeric_score * 100) |> Float.round |> trunc
  end

  def score(numeric_score) when is_integer(numeric_score) do
    numeric_score
  end

  def ago(nil) do
    content_tag(:span, "not yet", class: "time_ago not_yet", title: "NULL")
  end

  def ago(datetime) do
    rel = datetime
    |> Timex.format!("{relative}", :relative)

    abs = datetime
    |> Timex.Timezone.convert("America/Los_Angeles")
    |> Timex.format!("{ISO:Extended}")

    content_tag(:span, rel, class: "time_ago", title: abs)
  end

  def shift_ago(nil) do
    ago(nil)
  end

  def shift_ago(datetime) do
    datetime
    |> Timex.add(Timex.Duration.from_hours(7))
    |> ago
  end

  def team(_team = %Team{id: id, name: name, shortname: shortname}) do
    content = "#{shortname} (#{id})"
    content_tag(:span, content, class: "team", title: name)
  end

  def cbid(_rep = %Replacement{challenge_set: cset = %ChallengeSet{},
                               challenge_binary: cb = %ChallengeBinary{}}) do
    ChallengeBinary.cbid(cb, cset)
  end

  def cbid(cb = %ChallengeBinary{}, cset = %ChallengeSet{}) do
    ChallengeBinary.cbid(cb, cset)
  end

  def(csid(%ChallengeSet{shortname: sn}), do: sn)

  def csid(_fw = %Firewall{challenge_set: cset = %ChallengeSet{}}) do
    cset.shortname
  end

  def digest(dig) do
    minihash = :crypto.hash(:sha256, dig)
    |> Base.encode16
    |> String.slice(0..2)

    trunc = String.slice(dig, 0..8)

    css = "background-color: \##{minihash}"

    box = content_tag(:span, " ", class: "minihash", style: css)

    content_tag(:span, [box, trunc], class: "digest", title: dig)
  end
end
