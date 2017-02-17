defmodule Teaminterface.Repo.Migrations.ValidatePollerSeedUniqueness do
  use Ecto.Migration

  def change do
    create index(:pollers,
                 [:challenge_set_id, :round_id, :seed],
                 unique: true)
  end
end
