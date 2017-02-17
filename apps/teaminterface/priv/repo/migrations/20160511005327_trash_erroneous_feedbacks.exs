defmodule Teaminterface.Repo.Migrations.TrashErroneousFeedbacks do
  use Ecto.Migration

  def change do
    drop table :poll_feedbacks
    drop table :replacement_feedbacks
    drop table :proof_feedbacks
  end
end
