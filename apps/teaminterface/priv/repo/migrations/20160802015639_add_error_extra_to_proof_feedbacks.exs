defmodule Teaminterface.Repo.Migrations.AddErrorExtraToProofFeedbacks do
  use Ecto.Migration

  def change do
    alter table(:proof_feedbacks) do
      add(:error_extra, :binary)
    end
  end
end
