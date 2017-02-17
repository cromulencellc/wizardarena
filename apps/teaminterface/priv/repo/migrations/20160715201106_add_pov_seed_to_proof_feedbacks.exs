defmodule Teaminterface.Repo.Migrations.AddPovSeedToProofFeedbacks do
  use Ecto.Migration

  def change do
    alter table(:proof_feedbacks) do
      add :pov_seed, :binary
    end
  end
end
