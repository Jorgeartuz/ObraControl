-- ============================================================================
-- ObraControl — Macro-bloque 4, Bloque 1A: Fundación del acceso compartido
-- ============================================================================
-- ESTADO: NO EJECUTADO. Documentación / propuesta de DDL, preparada tras dos
-- rondas de revisión técnica (arquitectura + seguridad/RLS/offline-first) y
-- corregida con el esquema REAL confirmado en Supabase el 2026-09-23 (ver
-- Sección 0.B). Ninguna sentencia de este archivo fue corrida contra el
-- proyecto Supabase real. Debe revisarse y ejecutarse manualmente.
--
-- TABLAS QUE REALMENTE EXISTEN HOY (confirmado en Supabase, no supuesto):
--   profiles, projects, daily_records, daily_record_photos,
--   material_entries, material_exits, machinery.
-- TABLAS QUE **NO** EXISTEN (no crear aquí; son otro problema separado):
--   machinery_usage_logs, dump_truck_logs.
-- TABLA QUE ESTE ARCHIVO SÍ CREA:
--   project_members (nueva).
--
-- ALCANCE DE ESTE BLOQUE (1A — fundación, NO activación):
--   1. Tabla `project_members` (nueva, sin conflicto con nada existente).
--   2. Funciones de autorización `security definer`.
--   3. Triggers de inmutabilidad de `created_by`/`project_id`, SOLO sobre
--      las 5 tablas que realmente los necesitan y realmente existen.
--   3B. Trigger de inmutabilidad propio de `project_members` sobre
--      `project_id`/`user_id`/`invited_by`, para que una membresía
--      represente de forma estable "usuario X pertenece a proyecto Y" y
--      `invited_by` conserve quién la originó.
--   4. Policies propias de `project_members` (tabla nueva → no reemplaza nada).
--   5. Sección de diagnóstico + referencia con los nombres REALES de policy
--      de las 6 tablas existentes + storage, ya confirmados en Supabase,
--      para que el bloque que active el modelo de acceso no tenga que
--      volver a descubrirlos.
--
-- EXPLÍCITAMENTE FUERA DE ESTE BLOQUE (no incluido en este archivo):
--   - Reemplazo/DROP de ninguna policy existente en projects, daily_records,
--     daily_record_photos, material_entries, material_exits, machinery o
--     storage.objects.
--   - Creación de machinery_usage_logs / dump_truck_logs (fuera de alcance,
--     problema separado).
--   - Activación del modelo de acceso nuevo (propietario/miembro) en las
--     6 tablas existentes. Hoy siguen exactamente como están: cualquier
--     autenticado puede ver/editar todo. Este bloque NO cambia eso.
--   - Roles reales (role queda como columna preparada, sin lógica).
--   - Sincronización de project_members desde Flutter.
--   - Tombstoning/poda local, UI de permission-denied, Home, compartir/
--     invitar, invitaciones por email.
--
-- NOTA SOBRE INTERFERENCIA CON SyncQueue (verificado en el código Flutter
-- actual, no solo supuesto): se revisaron los repositorios con método de
-- edición (`ProjectRepository.updateProject`, `DailyRecordRepository.
-- updateRecord`, `MaterialEntryRepository.updateEntry`, `MaterialExit
-- Repository.updateExit`, `MachineryRepository.updateMachine`). Todos
-- preservan `createdBy` desde la fila existente vía `copyWith(createdBy:
-- Value(existing.createdBy))` y ninguno recibe `projectId`/`project_id`
-- como parámetro de edición (solo se fija al crear). `SyncEngine.
-- processEntitySync` reenvía tal cual el payload ya construido por el
-- repositorio, así que tampoco introduce cambios de estas columnas al
-- sincronizar. Conclusión: los triggers de este archivo son inertes para
-- todo el código actual — solo se activarían ante un intento real de
-- modificar estas columnas, que hoy no ocurre en ningún flujo de la app.
-- ============================================================================


-- ============================================================================
-- SECCIÓN 0.A — DIAGNÓSTICO EN VIVO (SOLO LECTURA, re-ejecutable)
-- ============================================================================
-- Útil para volver a confirmar el estado real antes del bloque que active
-- RLS sobre las tablas existentes, por si algo cambió entre este bloque y
-- ese. Solo consulta tablas que existen hoy.

select schemaname, tablename, policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in (
    'projects',
    'project_members',
    'daily_records',
    'daily_record_photos',
    'material_entries',
    'material_exits',
    'machinery'
  )
order by tablename, cmd;

-- storage.objects: el 2026-09-23 esta consulta devolvió "Success. No rows
-- returned" — hoy NO hay ninguna policy sobre storage.objects para ningún
-- bucket. Se deja para volver a confirmarlo más adelante (podría cambiar).
select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'storage'
  and tablename = 'objects'
order by cmd;

-- Disponibilidad de gen_random_uuid() (extensión pgcrypto), necesaria para
-- el default de project_members.id:
select extname, extversion
from pg_extension
where extname = 'pgcrypto';

select proname, pronamespace::regnamespace as schema
from pg_proc
where proname = 'gen_random_uuid';


-- ============================================================================
-- SECCIÓN 0.B — ESQUEMA REAL CONFIRMADO EN SUPABASE (2026-09-23)
-- ============================================================================
-- Documentación pura (comentarios), no ejecutable. Resultado de correr la
-- Sección 0.A (versión anterior de este archivo) contra el proyecto real.
-- Esto es lo que hace que este archivo quede "preparado" para el bloque que
-- active RLS sobre las tablas existentes sin tener que redescubrir nombres.
--
-- Columnas relevantes confirmadas:
--   projects.id                    uuid
--   projects.created_by            uuid NOT NULL
--   daily_records.id               uuid
--   daily_records.project_id       uuid NOT NULL
--   daily_records.created_by       uuid NOT NULL
--   daily_record_photos.id             uuid
--   daily_record_photos.daily_record_id uuid NOT NULL
--   daily_record_photos.created_by      uuid NOT NULL
--   material_entries.project_id    uuid NOT NULL
--   material_entries.created_by    uuid NOT NULL
--   material_exits.project_id      uuid NOT NULL
--   material_exits.created_by      uuid NOT NULL
--   machinery.project_id           uuid NOT NULL
--   machinery.created_by           uuid NOT NULL
--
-- Modelo de policies actual (las 6 tablas siguen exactamente este patrón):
--   SELECT: using (true)                       — cualquier autenticado ve todo
--   UPDATE: using (true)                       — cualquier autenticado edita todo
--   DELETE: using (true)                       — cualquier autenticado borra todo
--   INSERT: with check (created_by = auth.uid()) — solo se puede insertar
--           como uno mismo
--
-- Nombres reales de policy (para el bloque futuro de activación — NO se
-- tocan en este archivo, solo se documentan):
--   projects_select_authenticated
--   projects_insert_authenticated
--   projects_update_authenticated
--   projects_delete_authenticated
--   daily_records_select_authenticated
--   daily_records_insert_authenticated
--   daily_records_update_authenticated
--   daily_records_delete_authenticated
--   daily_record_photos_select_authenticated
--   daily_record_photos_insert_authenticated
--   daily_record_photos_update_authenticated
--   daily_record_photos_delete_authenticated
--   material_entries_select_authenticated
--   material_entries_insert_authenticated
--   material_entries_update_authenticated
--   material_entries_delete_authenticated
--   material_exits_select_authenticated
--   material_exits_insert_authenticated
--   material_exits_update_authenticated
--   material_exits_delete_authenticated
--   machinery_select_authenticated
--   machinery_insert_authenticated
--   machinery_update_authenticated
--   machinery_delete_authenticated
--
-- storage.objects: cero policies hoy (bucket probablemente no creado
-- todavía, o creado sin policies). El bloque futuro parte de cero aquí,
-- no de un reemplazo.
-- ============================================================================


-- ============================================================================
-- SECCIÓN 1 — TABLA project_members (nueva, no reemplaza nada existente)
-- ============================================================================
create table if not exists public.project_members (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member',
  invited_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  unique (project_id, user_id)
);

create index if not exists idx_project_members_project_id
  on public.project_members(project_id);
create index if not exists idx_project_members_user_id
  on public.project_members(user_id);

alter table public.project_members enable row level security;


-- ============================================================================
-- SECCIÓN 2 — FUNCIONES DE AUTORIZACIÓN (security definer)
-- ============================================================================
-- search_path fijado + referencias completamente calificadas (public.xxx)
-- para prevenir "search path hijacking".
--
-- SOBRE LA RECURSIÓN project_members -> has_project_access() ->
-- is_project_member() -> project_members:
-- SECURITY DEFINER hace que el cuerpo de la función corra con los
-- privilegios del DUEÑO de la función, no del invocador — pero eso por sí
-- solo NO evita la RLS. En Postgres, RLS se evita sobre una tabla solo si
-- quien la consulta es (a) el dueño de esa tabla y la tabla NO tiene
-- `FORCE ROW LEVEL SECURITY` activado, o (b) un rol con el atributo
-- BYPASSRLS. Por lo tanto, esta cadena NO recursiona solo si el rol que
-- posee (`proowner`) estas tres funciones es también el dueño de
-- `public.project_members` (o tiene BYPASSRLS), y `project_members` no
-- tiene FORCE RLS activado (este archivo no lo activa).
-- En Supabase, el SQL Editor ejecuta normalmente como un rol administrador
-- (`postgres`) que además es el dueño por defecto de las tablas creadas en
-- `public`, así que esta condición se cumple automáticamente si este
-- archivo se ejecuta desde ahí sin cambiar de rol. AUN ASÍ, no debe
-- asumirse sin verificar: ver Sección 2.B (verificación post-creación,
-- comentada, para correr manualmente después de este bloque).
create or replace function public.is_project_owner(p_project_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.projects
    where id = p_project_id
      and created_by = auth.uid()
  );
$$;

create or replace function public.is_project_member(p_project_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.project_members
    where project_id = p_project_id
      and user_id = auth.uid()
  );
$$;

create or replace function public.has_project_access(p_project_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select public.is_project_owner(p_project_id)
      or public.is_project_member(p_project_id);
$$;

-- Cierre explícito de permisos de ejecución (no depender del default de
-- Postgres, que otorga EXECUTE a PUBLIC en funciones nuevas):
revoke execute on function public.is_project_owner(uuid) from public;
revoke execute on function public.is_project_member(uuid) from public;
revoke execute on function public.has_project_access(uuid) from public;

grant execute on function public.is_project_owner(uuid) to authenticated;
grant execute on function public.is_project_member(uuid) to authenticated;
grant execute on function public.has_project_access(uuid) to authenticated;


-- ============================================================================
-- SECCIÓN 2.B — VERIFICACIÓN POST-CREACIÓN (comentada, NO ejecutar aquí)
-- ============================================================================
-- Correr manualmente DESPUÉS de haber ejecutado las secciones 1 y 2, antes
-- de confiar en estas funciones para las policies del bloque que active RLS
-- sobre las 6 tablas existentes. Confirma el supuesto de la Sección 2 en
-- lugar de asumirlo.

-- select current_user, session_user;

-- select r.rolname, r.rolbypassrls
-- from pg_roles r
-- where r.rolname = current_user;

-- select p.proname,
--        p.proowner::regrole as function_owner,
--        c.relname,
--        c.relowner::regrole as table_owner,
--        (p.proowner = c.relowner) as owners_match
-- from pg_proc p
-- cross join pg_class c
-- where p.pronamespace = 'public'::regnamespace
--   and p.proname in ('is_project_owner', 'is_project_member', 'has_project_access')
--   and c.relnamespace = 'public'::regnamespace
--   and c.relname in ('projects', 'project_members');

-- select relname, relforcerowsecurity
-- from pg_class
-- where relnamespace = 'public'::regnamespace
--   and relname in ('projects', 'project_members');

-- Si `owners_match` es false para is_project_member/project_members, o si
-- el rol no tiene rolbypassrls y no es dueño de project_members, la cadena
-- SELECT de project_members -> has_project_access -> is_project_member SÍ
-- podría recursionar (o simplemente devolver "acceso denegado" por RLS
-- interna) y hay que resolverlo (p.ej. recreando las funciones con el rol
-- correcto) antes de avanzar al siguiente bloque.


-- ============================================================================
-- SECCIÓN 3 — TRIGGERS DE INMUTABILIDAD
-- ============================================================================
-- Corrigen la vulnerabilidad de escalada de privilegios detectada en la
-- segunda revisión: sin esto, una policy de UPDATE del tipo
-- `with check (created_by = auth.uid() or is_project_member(id))` permite
-- que cualquier miembro reescriba created_by a su propio uid y se apropie
-- de una obra ajena (el `with check` valida la fila NUEVA, no que la
-- columna no haya cambiado; eso solo puede impedirse con un trigger, ya
-- que RLS no tiene acceso a OLD). Mismo razonamiento para project_id en las
-- tablas hijas: sin el trigger, un miembro podría "transferir" un registro
-- a otro proyecto al que también tiene acceso mediante un UPDATE.
--
-- La función es explícita por tabla (branch por TG_TABLE_NAME) en vez de
-- asumir "si no es projects, entonces tiene project_id": así, si en el
-- futuro este trigger se llega a adjuntar por error a una tabla no
-- contemplada aquí, falla con un error claro en vez de fallar de forma
-- confusa (columna inexistente) o, peor, no hacer nada.
--
-- Se aplica SOLO a las 5 tablas que existen hoy y que realmente necesitan
-- esta protección: projects (created_by), daily_records, material_entries,
-- material_exits, machinery (project_id). NO se crean triggers para
-- machinery_usage_logs ni dump_truck_logs porque esas tablas no existen.
-- daily_record_photos queda fuera porque no tiene columna project_id
-- directa (se llega a ella vía join con daily_records); su protección de
-- integridad se diseñará junto con la RLS del bloque que active el modelo
-- de acceso (fuera de alcance de 1A).

create or replace function public.prevent_ownership_column_change()
returns trigger
language plpgsql
as $$
begin
  case TG_TABLE_NAME
    when 'projects' then
      if NEW.created_by is distinct from OLD.created_by then
        raise exception 'created_by no puede modificarse una vez asignado (tabla projects)';
      end if;
    when 'daily_records' then
      if NEW.project_id is distinct from OLD.project_id then
        raise exception 'project_id no puede modificarse una vez asignado (tabla daily_records)';
      end if;
    when 'material_entries' then
      if NEW.project_id is distinct from OLD.project_id then
        raise exception 'project_id no puede modificarse una vez asignado (tabla material_entries)';
      end if;
    when 'material_exits' then
      if NEW.project_id is distinct from OLD.project_id then
        raise exception 'project_id no puede modificarse una vez asignado (tabla material_exits)';
      end if;
    when 'machinery' then
      if NEW.project_id is distinct from OLD.project_id then
        raise exception 'project_id no puede modificarse una vez asignado (tabla machinery)';
      end if;
    else
      raise exception 'prevent_ownership_column_change: tabla % no está autorizada para este trigger', TG_TABLE_NAME;
  end case;
  return NEW;
end;
$$;

drop trigger if exists trg_projects_lock_created_by on public.projects;
create trigger trg_projects_lock_created_by
  before update on public.projects
  for each row execute function public.prevent_ownership_column_change();

drop trigger if exists trg_daily_records_lock_project_id on public.daily_records;
create trigger trg_daily_records_lock_project_id
  before update on public.daily_records
  for each row execute function public.prevent_ownership_column_change();

drop trigger if exists trg_material_entries_lock_project_id on public.material_entries;
create trigger trg_material_entries_lock_project_id
  before update on public.material_entries
  for each row execute function public.prevent_ownership_column_change();

drop trigger if exists trg_material_exits_lock_project_id on public.material_exits;
create trigger trg_material_exits_lock_project_id
  before update on public.material_exits
  for each row execute function public.prevent_ownership_column_change();

drop trigger if exists trg_machinery_lock_project_id on public.machinery;
create trigger trg_machinery_lock_project_id
  before update on public.machinery
  for each row execute function public.prevent_ownership_column_change();


-- ============================================================================
-- SECCIÓN 3B — INMUTABILIDAD DE project_members (project_id/user_id/invited_by)
-- ============================================================================
-- Función dedicada y separada de `prevent_ownership_column_change()`: NO se
-- reutiliza esa función ni se le agrega una rama para `project_members`,
-- para no alterar en absoluto el comportamiento de los 5 triggers ya
-- definidos en la Sección 3 (siguen intactos, sin tocar).
--
-- Objetivo: una fila de `project_members` debe representar de forma
-- estable el hecho "usuario X pertenece a proyecto Y" — ni `project_id` ni
-- `user_id` pueden reasignarse después de creada la membresía (eso
-- equivaldría a borrarla y crear una distinta, no a "editarla"). `invited_by`
-- también se congela, para que conserve de forma fiable quién originó la
-- membresía y no pueda reescribirse retroactivamente.
--
-- Con este trigger, el único campo que un UPDATE real puede cambiar en
-- `project_members` es `role` (columna preparada, sin lógica de roles
-- todavía — ver Sección 4). La policy `project_members_update_owner_only`
-- (Sección 4, sin cambios) sigue siendo la única que autoriza ese UPDATE.

create or replace function public.prevent_project_members_identity_change()
returns trigger
language plpgsql
as $$
begin
  if NEW.project_id is distinct from OLD.project_id then
    raise exception 'project_id no puede modificarse una vez creada la membresía (tabla project_members)';
  end if;
  if NEW.user_id is distinct from OLD.user_id then
    raise exception 'user_id no puede modificarse una vez creada la membresía (tabla project_members)';
  end if;
  if NEW.invited_by is distinct from OLD.invited_by then
    raise exception 'invited_by no puede modificarse una vez creada la membresía (tabla project_members)';
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_project_members_lock_identity on public.project_members;
create trigger trg_project_members_lock_identity
  before update on public.project_members
  for each row execute function public.prevent_project_members_identity_change();


-- ============================================================================
-- SECCIÓN 4 — POLICIES DE project_members (tabla nueva, no reemplaza nada)
-- ============================================================================
-- Sin estas policies, project_members quedaría con RLS habilitada pero sin
-- ninguna policy — es decir, completamente inaccesible incluso para el
-- propio dueño de una obra. Se activan ahora porque no reemplazan ninguna
-- policy preexistente (la tabla es nueva); NO tocan las 6 tablas existentes.
--
-- Cobertura explícita de los tres riesgos señalados:
--   - "Un miembro no puede agregarse a sí mismo arbitrariamente": INSERT
--     exige is_project_owner(project_id), así que ningún no-propietario
--     puede insertar ninguna fila, para sí mismo o para otros.
--   - "Un miembro no puede modificar su propia membresía": UPDATE exige
--     is_project_owner(project_id) tanto en using como en with check, así
--     que ni siquiera el propio miembro afectado puede editar su fila.
--   - "Un miembro no puede eliminar la membresía de otro usuario": DELETE
--     solo permite user_id = auth.uid() (auto-abandono) o al propietario;
--     un miembro no puede borrar la fila de otro miembro.
--   Adicionalmente, tanto INSERT como UPDATE excluyen explícitamente que
--   user_id sea el propio created_by del proyecto: el propietario nunca
--   debe tener una fila propia en project_members (la propiedad es
--   implícita vía projects.created_by, según el diseño aprobado), así se
--   evita un estado ambiguo por error humano o de aplicación.

create policy "project_members_select" on public.project_members
  for select to authenticated
  using (public.has_project_access(project_id));

create policy "project_members_insert_owner_only" on public.project_members
  for insert to authenticated
  with check (
    public.is_project_owner(project_id)
    and (invited_by = auth.uid() or invited_by is null)
    and user_id <> (
      select p.created_by from public.projects p where p.id = project_id
    )
  );

create policy "project_members_update_owner_only" on public.project_members
  for update to authenticated
  using (public.is_project_owner(project_id))
  with check (
    public.is_project_owner(project_id)
    and user_id <> (
      select p.created_by from public.projects p where p.id = project_id
    )
  );

create policy "project_members_delete" on public.project_members
  for delete to authenticated
  using (public.is_project_owner(project_id) or user_id = auth.uid());

grant select, insert, update, delete on public.project_members to authenticated;


-- ============================================================================
-- SECCIÓN 5 — REFERENCIA PARA EL BLOQUE QUE ACTIVE RLS (NO EJECUTABLE)
-- ============================================================================
-- Todo lo siguiente son COMENTARIOS, no SQL ejecutable: ni una sola línea
-- de esta sección corre aunque se ejecute el archivo completo de una vez.
-- Es solo el punto de partida documentado para el próximo bloque, que
-- reemplazará (con DROP POLICY + CREATE POLICY, usando los nombres reales
-- de la Sección 0.B) las policies SELECT/UPDATE/DELETE abiertas de las 6
-- tablas existentes por versiones que usen has_project_access()/
-- is_project_owner(), sin tocar el patrón de INSERT (que ya exige
-- created_by = auth.uid() y es compatible con el modelo nuevo tal cual).
--
-- Ejemplo de la forma que tendrá ese cambio (a diseñar y confirmar en el
-- bloque correspondiente, NO en este):
--
--   drop policy if exists "projects_select_authenticated" on public.projects;
--   create policy "projects_select_authenticated" on public.projects
--     for select to authenticated
--     using (public.has_project_access(id));
--
--   drop policy if exists "daily_records_select_authenticated" on public.daily_records;
--   create policy "daily_records_select_authenticated" on public.daily_records
--     for select to authenticated
--     using (public.has_project_access(project_id));
--
--   -- (mismo patrón para material_entries, material_exits, machinery,
--   -- usando sus respectivas columnas project_id, y para daily_record_photos
--   -- vía join con daily_records.project_id).
--
-- storage.objects parte de cero (hoy sin policies): el bloque futuro
-- deberá crear ahí policies nuevas basadas en storage.foldername(name)
-- para derivar el project_id del path
-- `projects/{projectId}/daily_records/{dailyRecordId}/{photoId}.{ext}`.
-- ============================================================================


-- ============================================================================
-- FIN DEL BLOQUE 1A
-- ============================================================================
-- Estado tras ejecutar este archivo (cuando se decida ejecutar):
--   - project_members existe, con RLS propia funcional.
--   - Las funciones de autorización existen y están listas para reutilizarse
--     en las 6 tablas existentes en un bloque futuro (previa verificación
--     de la Sección 2.B).
--   - Los triggers de inmutabilidad protegen created_by/project_id en
--     projects, daily_records, material_entries, material_exits y
--     machinery — esto es intencional y seguro: como ningún flujo actual
--     de la app modifica esas columnas (verificado arriba), no cambia
--     ningún comportamiento hoy, y cierra la vulnerabilidad de antemano
--     para cuando se active el modelo de acceso.
--   - project_members tiene su propio trigger de inmutabilidad (Sección 3B,
--     independiente de los 5 anteriores) que congela project_id, user_id e
--     invited_by tras crear la membresía; solo `role` queda editable vía
--     la policy de UPDATE existente.
--   - Las policies de projects/daily_records/daily_record_photos/
--     material_entries/material_exits/machinery/storage.objects NO
--     cambiaron: el modelo actual ("cualquier autenticado ve y edita
--     todo") sigue vigente hasta el bloque que explícitamente las
--     reemplace, usando los nombres reales documentados en la Sección 0.B.
--   - machinery_usage_logs y dump_truck_logs siguen sin existir; no se
--     tocan en este archivo.
-- ============================================================================
