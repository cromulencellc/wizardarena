alias Teaminterface.Team

teams = __DIR__
|> Path.join("../repo/teams.tsv")
|> Path.expand
|> File.stream!([:read], :line)
|> Enum.map(&Team.seed_from_tsv_row(&1))
|> List.delete(nil)
