-- Migration 01_core : tables de base (hôtels, rooms, séjours, profils, rôles)
-- Cette migration ne contient pas encore les policies RLS (fichier dédié plus tard).

create table if not exists hotels (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    slug text unique not null,
    address text,
    timezone text not null default 'UTC',
    settings jsonb not null default '{}',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists rooms (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    label text not null,
    floor text,
    capacity integer,
    metadata jsonb not null default '{}',
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index if not exists rooms_hotel_id_idx on rooms(hotel_id);

create table if not exists room_qr_codes (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    room_id uuid not null references rooms(id) on delete cascade,
    token text not null unique,
    expires_at timestamptz,
    created_at timestamptz not null default now()
);
create index if not exists room_qr_codes_hotel_room_idx on room_qr_codes(hotel_id, room_id);

create table if not exists guest_profiles (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    auth_user_id uuid references auth.users(id) on delete set null,
    full_name text,
    email text,
    phone text,
    preferred_language text,
    created_at timestamptz not null default now()
);
create index if not exists guest_profiles_hotel_idx on guest_profiles(hotel_id);
create index if not exists guest_profiles_auth_user_idx on guest_profiles(auth_user_id);

create table if not exists staff_profiles (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    full_name text,
    email text,
    phone text,
    position text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create unique index if not exists staff_profiles_user_id_idx on staff_profiles(user_id);
create index if not exists staff_profiles_hotel_idx on staff_profiles(hotel_id);

create table if not exists roles (
    id serial primary key,
    code text not null unique,
    description text
);

create table if not exists user_roles (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    role_id integer not null references roles(id) on delete cascade,
    assigned_by uuid references staff_profiles(id) on delete set null,
    created_at timestamptz not null default now(),
    constraint user_roles_unique unique (hotel_id, user_id, role_id)
);
create index if not exists user_roles_hotel_idx on user_roles(hotel_id);
create index if not exists user_roles_user_idx on user_roles(user_id);

create table if not exists stays (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    room_id uuid not null references rooms(id) on delete restrict,
    primary_guest_id uuid references guest_profiles(id) on delete set null,
    qr_code_id uuid references room_qr_codes(id) on delete set null,
    check_in timestamptz not null,
    check_out timestamptz not null,
    status text not null check (status in ('booked', 'checked_in', 'checked_out', 'cancelled')),
    created_at timestamptz not null default now()
);
create index if not exists stays_hotel_idx on stays(hotel_id);
create index if not exists stays_room_idx on stays(room_id);

create table if not exists stay_guests (
    id uuid primary key default gen_random_uuid(),
    stay_id uuid not null references stays(id) on delete cascade,
    guest_id uuid not null references guest_profiles(id) on delete cascade,
    role text not null default 'secondary' check (role in ('primary', 'secondary')),
    invited_at timestamptz not null default now(),
    added_by uuid references staff_profiles(id) on delete set null,
    constraint stay_guests_unique unique (stay_id, guest_id)
);
create index if not exists stay_guests_stay_idx on stay_guests(stay_id);
create index if not exists stay_guests_guest_idx on stay_guests(guest_id);

-- Mise à jour automatique des timestamps updated_at
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger rooms_set_updated_at
before update on rooms
for each row execute function set_updated_at();

create trigger staff_profiles_set_updated_at
before update on staff_profiles
for each row execute function set_updated_at();
