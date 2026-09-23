-- ============================================================================
-- ObraControl — Macro-bloque 3: Backend y sincronización completa
-- ============================================================================
-- ESTADO: NO EJECUTADO. Este archivo es documentación / propuesta de DDL.
-- Ninguna sentencia de este archivo fue corrida contra el proyecto Supabase
-- real. Debe revisarse y ejecutarse manualmente (SQL editor de Supabase o
-- migración versionada) por quien administra el backend.
--
-- Contexto (inspeccionado desde el código Flutter, no desde el backend):
--   - Todas las tablas existentes (projects, daily_records, material_entries,
--     material_exits, machinery, daily_record_photos) usan id UUID y
--     created_by UUID -> profiles(id).
--   - El modelo de permisos actual es: cualquier usuario autenticado puede
--     hacer SELECT/INSERT/UPDATE/DELETE sobre los datos compartidos; los
--     usuarios anónimos no tienen acceso. Este script reproduce exactamente
--     ese modelo para las tablas nuevas, sin introducir roles ni
--     project_members.
--   - No se tuvo acceso a las políticas RLS reales de las tablas existentes
--     (no hay SQL versionado en el repo), así que las políticas de abajo son
--     una reconstrucción razonable de ese mismo modelo, no una copia literal.
--     Antes de ejecutar, compárense con las políticas reales de `machinery`
--     o `material_entries` en el dashboard de Supabase para mantener
--     coherencia exacta de nombres/convenciones si difieren.
--   - El script es repetible: usa IF NOT EXISTS / DROP POLICY IF EXISTS /
--     ON CONFLICT DO NOTHING en cada objeto, para poder correrlo más de una
--     vez sin que falle por "ya existe".
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1) TABLA: machinery_usage_logs (historial de horómetro)
-- ----------------------------------------------------------------------------
create table if not exists public.machinery_usage_logs (
  id uuid primary key,
  machine_id uuid not null references public.machinery(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  date timestamptz not null,
  horometer_start double precision not null check (horometer_start >= 0),
  horometer_end double precision not null check (horometer_end >= horometer_start),
  hours_worked double precision not null,
  observations text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  -- hours_worked debe ser no negativo Y coincidir con horometer_end -
  -- horometer_start. Se usa una tolerancia de 0.01 en vez de igualdad
  -- estricta: el cliente Flutter redondea hoursWorked a 2 decimales
  -- (toStringAsFixed(2)) antes de guardarlo, mientras que la resta en
  -- Postgres (double precision) no se redondea; una igualdad exacta
  -- rechazaría inserts legítimos por errores de redondeo de punto flotante.
  constraint machinery_usage_logs_hours_worked_valid check (
    hours_worked >= 0
    and abs(hours_worked - (horometer_end - horometer_start)) < 0.01
  )
);

create index if not exists idx_machinery_usage_logs_machine_id
  on public.machinery_usage_logs(machine_id);
create index if not exists idx_machinery_usage_logs_project_id
  on public.machinery_usage_logs(project_id);
create index if not exists idx_machinery_usage_logs_date
  on public.machinery_usage_logs(date);

alter table public.machinery_usage_logs enable row level security;

drop policy if exists "machinery_usage_logs_select_authenticated" on public.machinery_usage_logs;
create policy "machinery_usage_logs_select_authenticated"
  on public.machinery_usage_logs for select
  to authenticated
  using (true);

drop policy if exists "machinery_usage_logs_insert_authenticated" on public.machinery_usage_logs;
create policy "machinery_usage_logs_insert_authenticated"
  on public.machinery_usage_logs for insert
  to authenticated
  with check (created_by = auth.uid() or created_by is null);

drop policy if exists "machinery_usage_logs_update_authenticated" on public.machinery_usage_logs;
create policy "machinery_usage_logs_update_authenticated"
  on public.machinery_usage_logs for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "machinery_usage_logs_delete_authenticated" on public.machinery_usage_logs;
create policy "machinery_usage_logs_delete_authenticated"
  on public.machinery_usage_logs for delete
  to authenticated
  using (true);

grant select, insert, update, delete on public.machinery_usage_logs to authenticated;


-- ----------------------------------------------------------------------------
-- 2) TABLA: dump_truck_logs (control de entrada/salida de volquetas)
-- ----------------------------------------------------------------------------
create table if not exists public.dump_truck_logs (
  id uuid primary key,
  project_id uuid not null references public.projects(id) on delete cascade,
  plate text not null,
  driver text not null,
  material text not null,
  quantity double precision not null check (quantity > 0),
  unit text not null,
  date timestamptz not null,
  entry_time timestamptz not null,
  exit_time timestamptz,
  observations text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  constraint dump_truck_logs_exit_after_entry
    check (exit_time is null or exit_time >= entry_time)
);

create index if not exists idx_dump_truck_logs_project_id
  on public.dump_truck_logs(project_id);
create index if not exists idx_dump_truck_logs_plate
  on public.dump_truck_logs(plate);
create index if not exists idx_dump_truck_logs_entry_time
  on public.dump_truck_logs(entry_time);

alter table public.dump_truck_logs enable row level security;

drop policy if exists "dump_truck_logs_select_authenticated" on public.dump_truck_logs;
create policy "dump_truck_logs_select_authenticated"
  on public.dump_truck_logs for select
  to authenticated
  using (true);

drop policy if exists "dump_truck_logs_insert_authenticated" on public.dump_truck_logs;
create policy "dump_truck_logs_insert_authenticated"
  on public.dump_truck_logs for insert
  to authenticated
  with check (created_by = auth.uid() or created_by is null);

drop policy if exists "dump_truck_logs_update_authenticated" on public.dump_truck_logs;
create policy "dump_truck_logs_update_authenticated"
  on public.dump_truck_logs for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "dump_truck_logs_delete_authenticated" on public.dump_truck_logs;
create policy "dump_truck_logs_delete_authenticated"
  on public.dump_truck_logs for delete
  to authenticated
  using (true);

grant select, insert, update, delete on public.dump_truck_logs to authenticated;


-- ----------------------------------------------------------------------------
-- 3) SUPABASE STORAGE — fotografías de registro diario
-- ----------------------------------------------------------------------------
-- Bucket recomendado (crear manualmente desde Dashboard > Storage, o con el
-- insert de abajo). Privado (no público): el acceso se controla por RLS,
-- igual que el resto de datos de la app.
--
-- Nombre del bucket usado por el código Flutter (SyncEngine.photoStorageBucket):
--   daily-record-photos
--
-- Estructura de carpetas dentro del bucket:
--   projects/{projectId}/daily_records/{dailyRecordId}/{photoId}.{ext}
--
-- Ejemplo:
--   projects/8f2b.../daily_records/1a9c.../7e21....jpg

insert into storage.buckets (id, name, public)
values ('daily-record-photos', 'daily-record-photos', false)
on conflict (id) do nothing;

drop policy if exists "daily_record_photos_storage_select_authenticated" on storage.objects;
create policy "daily_record_photos_storage_select_authenticated"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'daily-record-photos');

drop policy if exists "daily_record_photos_storage_insert_authenticated" on storage.objects;
create policy "daily_record_photos_storage_insert_authenticated"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'daily-record-photos');

drop policy if exists "daily_record_photos_storage_update_authenticated" on storage.objects;
create policy "daily_record_photos_storage_update_authenticated"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'daily-record-photos')
  with check (bucket_id = 'daily-record-photos');

drop policy if exists "daily_record_photos_storage_delete_authenticated" on storage.objects;
create policy "daily_record_photos_storage_delete_authenticated"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'daily-record-photos');

-- NOTA: la tabla `daily_record_photos` YA EXISTE (id, daily_record_id,
-- storage_path, created_at, created_by) y no se modifica. Solo se necesita
-- confirmar que sus políticas RLS ya permiten INSERT/UPDATE/DELETE a
-- `authenticated` igual que las demás tablas (no se tocan aquí porque el
-- enunciado indica que esa tabla y su modelo de permisos ya existen).
-- ============================================================================
