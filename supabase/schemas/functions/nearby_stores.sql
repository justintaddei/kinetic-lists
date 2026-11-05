create extension if not exists postgis with schema extensions;

create function
nearby_stores(
  lat double precision,
  lng double precision,
  accuracy real default 0,
  radius_m real default 150
)
returns table (
  id uuid,
  name text,
  distance_m double precision
)
language sql
stable
as $$
select
  s.id,
  s.name,
  st_distance(s.location, cast(st_point(lng, lat) as geography)) as distance_m
from
  stores as s
where
  st_dwithin(
    s.location,
    cast(st_point(lng, lat) as geography),
    radius_m + least(accuracy, 100) + least(coalesce(s.accuracy_m, 0), 100)
  )
order by distance_m;
$$;
