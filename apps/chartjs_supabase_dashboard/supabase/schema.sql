-- The database of the live dashboard sample: one table of time-stamped
-- values. The anon role reads the table and asks for a new row through the
-- function pump_metric; the database makes each value. Run it in the SQL
-- editor of the Supabase project. It is idempotent.

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

-- No client writes the table: pump_metric inserts the rows.
drop policy if exists "metric_points insert" on public.metric_points;
revoke insert, update, delete, truncate on public.metric_points
  from anon, authenticated;
grant select on public.metric_points to anon, authenticated;

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

-- Inserts the next row: the database makes the value. At most 40 rows a
-- second over all clients: the 40th newest row must be 1 second old.
create or replace function public.pump_metric()
returns bigint
language plpgsql volatile security definer set search_path = '' as $$
declare
  recent timestamptz;
  new_id bigint;
begin
  select ts into recent from public.metric_points
    order by id desc offset 39 limit 1;
  if recent is not null and recent > now() - interval '1 second' then
    return null;
  end if;
  insert into public.metric_points (value)
    values (public.metric_value(now()))
    returning id into new_id;
  return new_id;
end $$;

revoke all on function public.pump_metric() from public;
grant execute on function public.pump_metric() to anon, authenticated;

-- The history: one value a second for the last 6 hours, when the table is
-- empty, in the order of the time (the ids grow with ts).
insert into public.metric_points (ts, value)
select t, public.metric_value(t)
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
