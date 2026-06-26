-- Starting sheet with player details
create or replace view competition_starting_sheet as
select
  ss.id,
  ss.competition_id,
  c.name as competition_name,
  c.start_date,
  ss.round_number,
  ss.tee_time,
  ss.tee_number,
  ss.group_number,
  ss.entry_id,
  ce.player_id,
  u.name as full_name,
  u."handicapIndex" as handicap_index,
  ce.playing_handicap,
  ce.tee_color,
  ce.flight_name,
  ce.entry_status
from starting_sheets ss
join competition_entries ce on ce.id = ss.entry_id
join public."User" u on u.id = ce.player_id
join competitions c on c.id = ss.competition_id
order by ss.competition_id, ss.round_number, ss.tee_time, ss.group_number;

alter view competition_starting_sheet set (security_invoker = true);
