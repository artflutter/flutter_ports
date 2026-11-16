-- The database of the live dashboard sample: one table of time-stamped
-- values, at most one value in each slot of 5 seconds for each session.
-- Each browser signs in as an anonymous user (turn on "Allow anonymous
-- sign-ins" in the Auth settings). A session reads the shared history and
-- its own rows, and asks for a new row of its own through the function
-- pump_metric; the database makes each value. Run it in the SQL editor of
-- the Supabase project. It is idempotent.

create table if not exists public.metric_points (
  id bigint generated always as identity primary key,
  ts timestamptz not null default now(),
  value double precision not null check (value between -1000 and 1000)
);

-- The session of a row: null for the shared history.
alter table public.metric_points add column if not exists owner uuid;

-- Each ts is the start of a slot of 5 seconds. A table of an earlier
-- version of this script has rows with other times: the script deletes all
-- rows, and writes the shared history again below.
do $$
begin
  if exists (
    select 1 from public.metric_points
    where mod(extract(epoch from ts), 5) <> 0
  ) then
    truncate public.metric_points restart identity;
  end if;
end $$;

-- The chart loads its pages by time: a page is the rows of one cell of a
-- grid of 5000 seconds (1000 slots). This index serves the pages, and it
-- holds one row of a session (or of the shared history) in each slot. The
-- ids grow with ts.
drop index if exists public.metric_points_owner_id_idx;
create unique index if not exists metric_points_owner_ts_idx
  on public.metric_points (owner, ts) nulls not distinct;

alter table public.metric_points enable row level security;

-- A session reads the shared history and its own rows. Realtime applies
-- the same policy: each session gets its own inserts only.
drop policy if exists "metric_points read" on public.metric_points;
create policy "metric_points read" on public.metric_points
  for select to authenticated
  using (owner is null or owner = (select auth.uid()));

-- No client writes the table: pump_metric inserts the rows.
drop policy if exists "metric_points insert" on public.metric_points;
revoke all on public.metric_points from anon;
revoke insert, update, delete, truncate on public.metric_points
  from authenticated;
grant select on public.metric_points to authenticated;

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

-- Smooth value noise of the time t (seconds) on cells of period seconds:
-- a random value in [-1, 1) at each cell edge, from a hash of the cell and
-- salt, and a smoothstep between the two edges. It never repeats.
create or replace function public.metric_noise(
  t double precision, period double precision, salt bigint)
returns double precision
language sql immutable parallel safe set search_path = '' as $$
  select a + (b - a) * (f * f * (3 - 2 * f))
  from (
    select hashint8(i * 7919 + salt) / 2147483648.0::double precision as a,
           hashint8((i + 1) * 7919 + salt) / 2147483648.0::double precision as b,
           x - i as f
    from (select t / period as x, floor(t / period)::bigint as i) as cell
  ) as ends
$$;

-- The value at ts: noise of 40 minutes, 9 minutes, 2 minutes, 29 seconds
-- and 7 seconds around 50, and a slow noise that makes the two fast parts
-- calm or busy. The values stay in about 20 to 80. It depends on ts only,
-- so the rows of all clients lie on one curve.
create or replace function public.metric_value(ts timestamptz)
returns double precision
language sql immutable parallel safe set search_path = '' as $$
  select round((
      50
      + 20 * public.metric_noise(e, 2400, 101)
      + 10 * public.metric_noise(e, 540, 211)
      + 5 * public.metric_noise(e, 130, 307)
      + (1 + 0.8 * public.metric_noise(e, 900, 401))
        * (2.5 * public.metric_noise(e, 29, 503)
           + 1.0 * public.metric_noise(e, 7, 601))
    )::numeric, 2)::double precision
  from (select extract(epoch from ts)::double precision as e) as t
$$;

-- Inserts the row of the session for the current slot of 5 seconds, with
-- the start of the slot as its ts: the database makes the value. A session
-- gets at most one row in a slot (the unique index), and all sessions get
-- at most 200 rows in a slot (40 a second). Gives null for a skipped row.
create or replace function public.pump_metric()
returns bigint
language plpgsql volatile security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  slot timestamptz :=
    to_timestamp(floor(extract(epoch from now()) / 5)::double precision * 5);
  recent timestamptz;
  new_id bigint;
begin
  if me is null then
    return null;
  end if;
  select ts into recent from public.metric_points
    order by id desc offset 199 limit 1;
  if recent is not null and recent >= slot then
    return null;
  end if;
  insert into public.metric_points (owner, ts, value)
    values (me, slot, public.metric_value(slot))
    on conflict do nothing
    returning id into new_id;
  return new_id;
end $$;

revoke all on function public.pump_metric() from public, anon;
grant execute on function public.pump_metric() to authenticated;

-- The shared history (no owner): one value in each slot of 5 seconds of
-- the last 6 hours, when the table is empty, in the order of the time (the
-- ids grow with ts).
insert into public.metric_points (ts, value)
select t, public.metric_value(t)
from (
  select to_timestamp(floor(extract(epoch from now()) / 5)::double precision * 5)
    - make_interval(secs => g * 5) as t
  from generate_series(4320, 1, -1) as g
) as history
where not exists (select 1 from public.metric_points)
order by t;

-- The free plan has 500 MB: a job deletes the rows of a session after one
-- day. The shared history stays.
create extension if not exists pg_cron;

select cron.schedule(
  'metric_points_trim',
  '*/10 * * * *',
  $$delete from public.metric_points
    where owner is not null and ts < now() - interval '1 day'$$
);
