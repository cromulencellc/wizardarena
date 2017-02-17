defmodule Teaminterface.Repo.Migrations.EnablementsUniqueRoundIdChallengeSetIdIndex do
  use Ecto.Migration

  def change do
    drop index(:enablements,
               [:round_id, :challenge_set_id],
               unique: false)

    execute """
    DELETE FROM enablements
      WHERE id NOT IN (
        SELECT
          DISTINCT ON (round_id, challenge_set_id)
          id
          FROM enablements);
    """

    create index(:enablements,
                 [:round_id, :challenge_set_id],
                 unique: true)
  end
end
