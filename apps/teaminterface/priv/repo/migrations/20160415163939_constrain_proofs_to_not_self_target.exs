defmodule Teaminterface.Repo.Migrations.ConstrainProofsToNotSelfTarget do
  use Ecto.Migration

  def change do
    execute ~s"""
    ALTER TABLE proofs
    ADD CONSTRAINT cannot_self_target
    CHECK (team_id != target_id)
    """
  end
end
