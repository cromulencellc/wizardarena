defmodule Teaminterface.Repo.Migrations.ValidatePollFeedbackUniqueness do
  use Ecto.Migration

  def change do
    create index(:poll_feedbacks,
                 [:poller_id, :team_id],
                 unique: true)
  end
end
