-- Migration 05_support : audit logs et analytics

create table if not exists audit_logs (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    actor_type text not null check (actor_type in ('staff','guest','system')),
    actor_staff_id uuid references staff_profiles(id) on delete set null,
    actor_guest_id uuid references stay_guests(id) on delete set null,
    action text not null,
    entity text not null,
    entity_id uuid,
    metadata jsonb not null default '{}',
    created_at timestamptz not null default now(),
    constraint audit_logs_actor_consistency check (
        (actor_type = 'staff' and actor_staff_id is not null and actor_guest_id is null) or
        (actor_type = 'guest' and actor_guest_id is not null and actor_staff_id is null) or
        (actor_type = 'system' and actor_staff_id is null and actor_guest_id is null)
    )
);
create index if not exists audit_logs_hotel_idx on audit_logs(hotel_id);
create index if not exists audit_logs_entity_idx on audit_logs(hotel_id, entity, entity_id);
create index if not exists audit_logs_created_idx on audit_logs(created_at);

create table if not exists analytics_events (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    stay_id uuid references stays(id) on delete set null,
    event_type text not null,
    payload jsonb not null default '{}',
    occurred_at timestamptz not null default now()
);
create index if not exists analytics_events_hotel_idx on analytics_events(hotel_id);
create index if not exists analytics_events_type_idx on analytics_events(hotel_id, event_type);
create index if not exists analytics_events_time_idx on analytics_events(occurred_at);
