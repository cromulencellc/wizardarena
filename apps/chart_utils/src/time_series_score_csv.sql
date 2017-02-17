begin transaction;
create view time_series_scores as (select
  round_id,
  team_id,
  name,
  sum(contribution) over (partition by team_id order by round_id asc, team_id asc)
from (
select
  s.round_id,
  s.team_id,
  t.name,
  sum(round(1000 * (s.security * s.availability * s.evaluation))) as contribution
  from scores as s
  inner join teams as t on t.id = s.team_id
  group by s.round_id, s.team_id, t.name
  order by s.round_id asc, s.team_id asc
) as q
order by round_id asc, team_id asc);
\copy (select * from time_series_scores order by round_id asc, team_id asc) TO 'tmp/time_series_score.csv' CSV HEADER
rollback;
