defmodule Teaminterface.Repo.Migrations.AddPerformanceAndFunctionalityToScores do
  use Ecto.Migration

  def change do
    alter table(:scores) do
      add(:performance, :float)
      add(:functionality, :float)
    end
  end
end
