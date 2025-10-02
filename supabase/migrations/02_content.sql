-- Migration 02_content : tables informations pratiques, annonces et météo

create table if not exists info_pages (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    title text not null,
    slug text not null,
    content jsonb not null default '[]',
    visibility text not null default 'public' check (visibility in ('public', 'staff_only')),
    updated_by uuid references staff_profiles(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint info_pages_slug_unique unique (hotel_id, slug)
);
create index if not exists info_pages_hotel_idx on info_pages(hotel_id);

create table if not exists practical_info_sections (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    title text not null,
    description text,
    sort_order integer not null default 0,
    icon text,
    created_at timestamptz not null default now()
);
create index if not exists practical_info_sections_hotel_idx on practical_info_sections(hotel_id);

create table if not exists practical_info_items (
    id uuid primary key default gen_random_uuid(),
    section_id uuid not null references practical_info_sections(id) on delete cascade,
    hotel_id uuid not null references hotels(id) on delete cascade,
    label text not null,
    value text,
    details jsonb,
    info_type text not null default 'info' check (info_type in ('info','schedule','contact','amenity','faq')),
    icon text,
    sort_order integer not null default 0,
    created_at timestamptz not null default now()
);
create index if not exists practical_info_items_section_idx on practical_info_items(section_id);
create index if not exists practical_info_items_hotel_idx on practical_info_items(hotel_id);

create table if not exists opening_hours (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    section_id uuid references practical_info_sections(id) on delete set null,
    service_name text not null,
    day_of_week smallint not null check (day_of_week between 0 and 6),
    open_time time,
    close_time time,
    notes text,
    created_at timestamptz not null default now()
);
create index if not exists opening_hours_hotel_idx on opening_hours(hotel_id);
create index if not exists opening_hours_section_idx on opening_hours(section_id);

create table if not exists transport_links (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    type text not null check (type in ('bus','metro','train','taxi','shuttle','other')),
    name text not null,
    description text,
    contact jsonb,
    booking_url text,
    schedule jsonb,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index if not exists transport_links_hotel_idx on transport_links(hotel_id);

create table if not exists weather_snapshots (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    source text not null,
    payload jsonb not null,
    fetched_at timestamptz not null default now(),
    valid_until timestamptz,
    created_at timestamptz not null default now()
);
create index if not exists weather_snapshots_hotel_idx on weather_snapshots(hotel_id);
create index if not exists weather_snapshots_valid_idx on weather_snapshots(valid_until);

create table if not exists announcements (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    title text not null,
    body text,
    start_at timestamptz not null default now(),
    end_at timestamptz,
    priority text not null default 'normal' check (priority in ('normal','high')),
    created_by uuid references staff_profiles(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index if not exists announcements_hotel_idx on announcements(hotel_id);
create index if not exists announcements_period_idx on announcements(hotel_id, start_at, end_at);

create table if not exists announcement_targets (
    id uuid primary key default gen_random_uuid(),
    announcement_id uuid not null references announcements(id) on delete cascade,
    target_type text not null check (target_type in ('role','room','stay')),
    target_role_id integer references roles(id) on delete cascade,
    target_room_id uuid references rooms(id) on delete cascade,
    target_stay_id uuid references stays(id) on delete cascade,
    created_at timestamptz not null default now(),
    constraint announcement_targets_type_check check (
        (target_type = 'role' and target_role_id is not null and target_room_id is null and target_stay_id is null) or
        (target_type = 'room' and target_room_id is not null and target_role_id is null and target_stay_id is null) or
        (target_type = 'stay' and target_stay_id is not null and target_role_id is null and target_room_id is null)
    )
);
create index if not exists announcement_targets_announcement_idx on announcement_targets(announcement_id);

create table if not exists activities (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    title text not null,
    description text,
    location text,
    start_at timestamptz not null,
    end_at timestamptz,
    capacity integer,
    booking_required boolean not null default false,
    created_by uuid references staff_profiles(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index if not exists activities_hotel_idx on activities(hotel_id);
create index if not exists activities_period_idx on activities(hotel_id, start_at, end_at);

-- Triggers updated_at
create trigger info_pages_set_updated_at
before update on info_pages
for each row execute function set_updated_at();

create trigger transport_links_set_updated_at
before update on transport_links
for each row execute function set_updated_at();

create trigger activities_set_updated_at
before update on activities
for each row execute function set_updated_at();
