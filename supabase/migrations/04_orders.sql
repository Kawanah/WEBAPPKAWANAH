-- Migration 04_orders : catalogues, services, commandes room-service & transport

create table if not exists service_catalogs (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    type text not null check (type in ('room_service','transport')),
    title text not null,
    description text,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index if not exists service_catalogs_hotel_idx on service_catalogs(hotel_id);

create table if not exists service_items (
    id uuid primary key default gen_random_uuid(),
    catalog_id uuid not null references service_catalogs(id) on delete cascade,
    hotel_id uuid not null references hotels(id) on delete cascade,
    name text not null,
    description text,
    price numeric(10,2) not null default 0,
    currency text not null default 'EUR',
    preparation_time_minutes integer,
    is_available boolean not null default true,
    options_schema jsonb not null default '{}',
    created_by uuid references staff_profiles(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index if not exists service_items_catalog_idx on service_items(catalog_id);
create index if not exists service_items_hotel_idx on service_items(hotel_id);

create table if not exists service_options (
    id uuid primary key default gen_random_uuid(),
    service_item_id uuid not null references service_items(id) on delete cascade,
    label text not null,
    additional_price numeric(10,2) not null default 0,
    metadata jsonb not null default '{}'
);
create index if not exists service_options_item_idx on service_options(service_item_id);

create table if not exists catalog_roles (
    id uuid primary key default gen_random_uuid(),
    catalog_id uuid not null references service_catalogs(id) on delete cascade,
    role_id integer not null references roles(id) on delete cascade,
    access_level text not null check (access_level in ('manage','view')),
    created_at timestamptz not null default now(),
    constraint catalog_roles_unique unique (catalog_id, role_id)
);

create table if not exists tags (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    code text not null,
    label text not null,
    category text,
    color text,
    created_at timestamptz not null default now(),
    constraint tags_unique_code unique (hotel_id, code)
);
create index if not exists tags_hotel_idx on tags(hotel_id);

create table if not exists service_item_tags (
    id uuid primary key default gen_random_uuid(),
    service_item_id uuid not null references service_items(id) on delete cascade,
    tag_id uuid not null references tags(id) on delete cascade,
    created_at timestamptz not null default now(),
    constraint service_item_tags_unique unique (service_item_id, tag_id)
);
create index if not exists service_item_tags_item_idx on service_item_tags(service_item_id);

create table if not exists transport_partners (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    name text not null,
    contact jsonb,
    notes text,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index if not exists transport_partners_hotel_idx on transport_partners(hotel_id);

create table if not exists orders (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    stay_id uuid not null references stays(id) on delete cascade,
    catalog_id uuid references service_catalogs(id) on delete set null,
    requested_for text not null default 'now' check (requested_for in ('now','schedule')),
    scheduled_at timestamptz,
    status text not null default 'pending' check (status in ('pending','accepted','in_progress','completed','cancelled')),
    total_amount numeric(10,2) not null default 0,
    currency text not null default 'EUR',
    created_by_type text not null check (created_by_type in ('guest','staff')),
    created_by_guest_id uuid references stay_guests(id) on delete set null,
    created_by_staff_id uuid references staff_profiles(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint orders_created_by_consistency check (
        (created_by_type = 'guest' and created_by_guest_id is not null and created_by_staff_id is null) or
        (created_by_type = 'staff' and created_by_staff_id is not null and created_by_guest_id is null)
    )
);
create index if not exists orders_hotel_idx on orders(hotel_id);
create index if not exists orders_stay_idx on orders(stay_id);
create index if not exists orders_status_idx on orders(status);

create table if not exists order_items (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references orders(id) on delete cascade,
    service_item_id uuid references service_items(id) on delete set null,
    description text,
    quantity integer not null default 1 check (quantity > 0),
    unit_price numeric(10,2) not null default 0,
    options jsonb not null default '[]',
    notes text
);
create index if not exists order_items_order_idx on order_items(order_id);

create table if not exists order_item_options (
    id uuid primary key default gen_random_uuid(),
    order_item_id uuid not null references order_items(id) on delete cascade,
    service_option_id uuid references service_options(id) on delete set null,
    price_delta numeric(10,2) not null default 0,
    selected_at timestamptz not null default now()
);
create index if not exists order_item_options_item_idx on order_item_options(order_item_id);

create table if not exists order_assignments (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references orders(id) on delete cascade,
    staff_id uuid not null references staff_profiles(id) on delete cascade,
    assigned_role text not null default 'handler',
    assigned_at timestamptz not null default now(),
    unassigned_at timestamptz,
    constraint order_assignments_unique unique (order_id, staff_id, assigned_role)
);
create index if not exists order_assignments_order_idx on order_assignments(order_id);
create index if not exists order_assignments_staff_idx on order_assignments(staff_id);

create table if not exists order_status_history (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references orders(id) on delete cascade,
    from_status text,
    to_status text not null,
    changed_by_type text not null check (changed_by_type in ('guest','staff','system')),
    changed_by_guest_id uuid references stay_guests(id) on delete set null,
    changed_by_staff_id uuid references staff_profiles(id) on delete set null,
    comment text,
    changed_at timestamptz not null default now(),
    constraint order_status_history_consistency check (
        (changed_by_type = 'guest' and changed_by_guest_id is not null and changed_by_staff_id is null) or
        (changed_by_type = 'staff' and changed_by_staff_id is not null and changed_by_guest_id is null) or
        (changed_by_type = 'system' and changed_by_guest_id is null and changed_by_staff_id is null)
    )
);
create index if not exists order_status_history_order_idx on order_status_history(order_id);
create index if not exists order_status_history_changed_at_idx on order_status_history(changed_at);

-- Trigger pour recalculer total_amount
create or replace function orders_recalculate_total()
returns trigger as $$
declare
    total numeric(10,2);
begin
    select coalesce(sum((oi.unit_price + coalesce(sum(oio.price_delta),0)) * oi.quantity), 0)
      into total
      from order_items oi
      left join order_item_options oio on oio.order_item_id = oi.id
     where oi.order_id = new.order_id;

    update orders
       set total_amount = total,
           updated_at = now()
     where id = new.order_id;

    return new;
end;
$$ language plpgsql;

create trigger order_items_after_change
after insert or update or delete on order_items
for each row execute function orders_recalculate_total();

create trigger order_item_options_after_change
after insert or update or delete on order_item_options
for each row execute function orders_recalculate_total();

-- Trigger pour historiser les changements de statut
create or replace function orders_status_change()
returns trigger as $$
begin
  if coalesce(old.status, '') <> new.status then
    insert into order_status_history (order_id, from_status, to_status, changed_by_type, changed_by_guest_id, changed_by_staff_id, comment)
    values (
      new.id,
      old.status,
      new.status,
      case when new.created_by_staff_id is not null then 'staff' else 'guest' end,
      null,
      new.created_by_staff_id,
      null
    );
  end if;
  return new;
end;
$$ language plpgsql;

create trigger orders_status_change_trigger
after update on orders
for each row execute function orders_status_change();

-- Triggers updated_at
create trigger service_catalogs_set_updated_at
before update on service_catalogs
for each row execute function set_updated_at();

create trigger service_items_set_updated_at
before update on service_items
for each row execute function set_updated_at();

create trigger transport_partners_set_updated_at
before update on transport_partners
for each row execute function set_updated_at();

create trigger orders_set_updated_at
before update on orders
for each row execute function set_updated_at();
