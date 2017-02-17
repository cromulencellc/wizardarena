defmodule Teaminterface.Repo.Migrations.AddCountConstraintToProofs do
  use Ecto.Migration

  def change do
    alter table(:proofs) do
      modify(:target_id, :integer, null: false)
      modify(:throws, :integer, null: false)
    end

    execute ~s"""
    ALTER TABLE proofs
    ADD CONSTRAINT throws_in_one_through_ten
    CHECK (throws >= 1 AND throws <= 10)
    """
  end
end
