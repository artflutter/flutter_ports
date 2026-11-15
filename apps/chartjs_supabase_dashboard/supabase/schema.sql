-- The database of the live dashboard sample: one table of time-stamped
-- values, open to the anon role for reads and for inserts of a value only.
-- Run it in the SQL editor of the Supabase project. It is idempotent.

create table if not exists public.metric_points (
  id bigint generated always as identity primary key,
  ts timestamptz not null default now(),
  value double precision not null check (value between -1000 and 1000)
);

-- The chart loads its pages by id, the newest rows first: the primary key
-- is the index of the pages, and the ids grow with ts.

alter table public.metric_points enable row level security;

drop policy if exists "metric_points read" on public.metric_points;
create policy "metric_points read" on public.metric_points
  for select to anon, authenticated using (true);

drop policy if exists "metric_points insert" on public.metric_points;
create policy "metric_points insert" on public.metric_points
  for insert to anon, authenticated with check (true);

-- A client sends the value only: the database sets id and ts.
revoke insert, update, delete, truncate on public.metric_points
  from anon, authenticated;
grant select on public.metric_points to anon, authenticated;
grant insert (value) on public.metric_points to anon, authenticated;

-- Realtime sends each insert to the subscribers of the table.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'metric_points'
  ) then
    alter publication supabase_realtime add table public.metric_points;
  end if;
end $$;

-- The history: one value a second for the last 6 hours, when the table is
-- empty, in the order of the time (the ids grow with ts). The values have
-- the formula of the pump of the app (LiveSeries.nextValue).
insert into public.metric_points (ts, value)
select t, round((
    50 + 15 * sin(extract(epoch from t) / 90)
    + 6 * sin(extract(epoch from t) / 13)
    + (random() + random() - 1) * 0.6
  )::numeric, 2)
from (
  select date_trunc('second', now()) - make_interval(secs => g) as t
  from generate_series(21600, 1, -1) as g
) as history
where not exists (select 1 from public.metric_points)
order by t;

-- The free plan has 500 MB: a job keeps the newest 200000 rows.
create extension if not exists pg_cron;

select cron.schedule(
  'metric_points_trim',
  '*/10 * * * *',
  $$delete from public.metric_points
    where id < (select id from public.metric_points
                order by id desc offset 200000 limit 1)$$
);
