-- Migration 10_rls : fonctions helper et politiques Row Level Security

-- =========================
-- Helper functions
-- =========================

create or replace function public.current_user_id()
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select auth.uid();
$$;

grant execute on function public.current_user_id() to authenticated, service_role, anon;

create or replace function public.is_service_role()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select auth.role() = 'service_role';
$$;

grant execute on function public.is_service_role() to authenticated, service_role, anon;

create or replace function public.has_role(p_hotel uuid, p_roles text[])
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(
    exists (
      select 1
      from user_roles ur
      join roles r on r.id = ur.role_id
      where ur.hotel_id = p_hotel
        and ur.user_id = auth.uid()
        and r.code = any(p_roles)
    ), false
  );
$$;

grant execute on function public.has_role(uuid, text[]) to authenticated, service_role;

create or replace function public.current_staff_id()
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select sp.id
  from staff_profiles sp
  where sp.user_id = auth.uid()
  limit 1;
$$;

grant execute on function public.current_staff_id() to authenticated, service_role;

create or replace function public.current_guest_id()
returns uuid
language sql
security definer
set search_path = public
stable
as $$
  select gp.id
  from guest_profiles gp
  where gp.auth_user_id = auth.uid()
  limit 1;
$$;

grant execute on function public.current_guest_id() to authenticated, service_role;

create or replace function public.is_guest_for_stay(p_stay uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(
    exists (
      select 1
      from stay_guests sg
      join guest_profiles gp on gp.id = sg.guest_id
      where sg.stay_id = p_stay
        and gp.auth_user_id = auth.uid()
    ), false
  );
$$;

grant execute on function public.is_guest_for_stay(uuid) to authenticated;

create or replace function public.is_guest_for_hotel(p_hotel uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(
    exists (
      select 1
      from stays s
      join stay_guests sg on sg.stay_id = s.id
      join guest_profiles gp on gp.id = sg.guest_id
      where s.hotel_id = p_hotel
        and gp.auth_user_id = auth.uid()
        and s.status in ('booked','checked_in')
    ), false
  );
$$;

grant execute on function public.is_guest_for_hotel(uuid) to authenticated;

-- =========================
-- Core entities
-- =========================

-- hotels
alter table hotels enable row level security;
alter table hotels force row level security;

drop policy if exists "hotels service" on hotels;
create policy "hotels service" on hotels
  for all
  using (is_service_role())
  with check (is_service_role());

drop policy if exists "hotels staff read" on hotels;
create policy "hotels staff read" on hotels
  for select
  using (is_service_role() or has_role(id, array['admin','manager','staff']));

-- rooms
alter table rooms enable row level security;
alter table rooms force row level security;

drop policy if exists "rooms read" on rooms;
create policy "rooms read" on rooms
  for select
  using (
    is_service_role()
    or has_role(hotel_id, array['admin','manager','staff'])
    or is_guest_for_hotel(hotel_id)
  );

drop policy if exists "rooms manage" on rooms;
create policy "rooms manage" on rooms
  for all
  using (is_service_role() or has_role(hotel_id, array['admin','manager']))
  with check (is_service_role() or has_role(hotel_id, array['admin','manager']));

-- room_qr_codes
alter table room_qr_codes enable row level security;
alter table room_qr_codes force row level security;

drop policy if exists "room_qr staff" on room_qr_codes;
create policy "room_qr staff" on room_qr_codes
  for all
  using (is_service_role() or has_role(hotel_id, array['admin','manager']))
  with check (is_service_role() or has_role(hotel_id, array['admin','manager']));

-- guest_profiles
alter table guest_profiles enable row level security;
alter table guest_profiles force row level security;

drop policy if exists "guest_profiles service" on guest_profiles;
create policy "guest_profiles service" on guest_profiles
  for all
  using (is_service_role())
  with check (is_service_role());

drop policy if exists "guest_profiles staff" on guest_profiles;
create policy "guest_profiles staff" on guest_profiles
  for select
  using (is_service_role() or has_role(hotel_id, array['admin','manager','staff']));

drop policy if exists "guest_profiles self" on guest_profiles;
create policy "guest_profiles self" on guest_profiles
  for select
  using (auth.uid() is not null and auth.uid() = auth_user_id);

-- staff_profiles
alter table staff_profiles enable row level security;
alter table staff_profiles force row level security;

drop policy if exists "staff_profiles service" on staff_profiles;
create policy "staff_profiles service" on staff_profiles
  for all
  using (is_service_role())
  with check (is_service_role());

drop policy if exists "staff_profiles staff" on staff_profiles;
create policy "staff_profiles staff" on staff_profiles
  for select
  using (is_service_role() or has_role(hotel_id, array['admin','manager']));

-- stays
alter table stays enable row level security;
alter table stays force row level security;

drop policy if exists "stays staff" on stays;
create policy "stays staff" on stays
  for all
  using (is_service_role() or has_role(hotel_id, array['admin','manager','staff']))
  with check (is_service_role() or has_role(hotel_id, array['admin','manager','staff']));

drop policy if exists "stays guests" on stays;
create policy "stays guests" on stays
  for select
  using (is_guest_for_stay(id));

-- stay_guests
alter table stay_guests enable row level security;
alter table stay_guests force row level security;

drop policy if exists "stay_guests staff" on stay_guests;
create policy "stay_guests staff" on stay_guests
  for all
  using (is_service_role() or has_role((select hotel_id from stays where id = stay_id), array['admin','manager','staff']))
  with check (is_service_role() or has_role((select hotel_id from stays where id = stay_id), array['admin','manager','staff']));

drop policy if exists "stay_guests guest" on stay_guests;
create policy "stay_guests guest" on stay_guests
  for select
  using (is_guest_for_stay(stay_id));

-- roles (lecture service seulement)
alter table roles enable row level security;
alter table roles force row level security;

drop policy if exists "roles service" on roles;
create policy "roles service" on roles
  for all
  using (is_service_role())
  with check (is_service_role());

-- user_roles
alter table user_roles enable row level security;
alter table user_roles force row level security;

drop policy if exists "user_roles service" on user_roles;
create policy "user_roles service" on user_roles
  for all
  using (is_service_role())
  with check (is_service_role());

drop policy if exists "user_roles staff" on user_roles;
create policy "user_roles staff" on user_roles
  for select
  using (is_service_role() or has_role(hotel_id, array['admin']));

-- =========================
-- Informations & météo
-- =========================

-- helper to add read/write pattern
create or replace function public.can_manage_content(p_hotel uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select is_service_role() or has_role(p_hotel, array['admin','manager']);
$$;

grant execute on function public.can_manage_content(uuid) to authenticated, service_role;

-- info_pages
alter table info_pages enable row level security;
alter table info_pages force row level security;

drop policy if exists "info_pages read" on info_pages;
create policy "info_pages read" on info_pages
  for select
  using (
    is_service_role()
    or has_role(hotel_id, array['admin','manager','staff'])
    or is_guest_for_hotel(hotel_id)
  );

drop policy if exists "info_pages write" on info_pages;
create policy "info_pages write" on info_pages
  for all
  using (can_manage_content(hotel_id))
  with check (can_manage_content(hotel_id));

-- practical_info_sections
alter table practical_info_sections enable row level security;
alter table practical_info_sections force row level security;

drop policy if exists "pi_sections read" on practical_info_sections;
create policy "pi_sections read" on practical_info_sections
  for select
  using (
    is_service_role()
    or has_role(hotel_id, array['admin','manager','staff'])
    or is_guest_for_hotel(hotel_id)
  );

drop policy if exists "pi_sections write" on practical_info_sections;
create policy "pi_sections write" on practical_info_sections
  for all
  using (can_manage_content(hotel_id))
  with check (can_manage_content(hotel_id));

-- practical_info_items
alter table practical_info_items enable row level security;
alter table practical_info_items force row level security;

drop policy if exists "pi_items read" on practical_info_items;
create policy "pi_items read" on practical_info_items
  for select
  using (
    is_service_role()
    or has_role(hotel_id, array['admin','manager','staff'])
    or is_guest_for_hotel(hotel_id)
  );

drop policy if exists "pi_items write" on practical_info_items;
create policy "pi_items write" on practical_info_items
  for all
  using (can_manage_content(hotel_id))
  with check (can_manage_content(hotel_id));

-- opening_hours
alter table opening_hours enable row level security;
alter table opening_hours force row level security;

drop policy if exists "opening_hours read" on opening_hours;
create policy "opening_hours read" on opening_hours
  for select
  using (
    is_service_role()
    or has_role(hotel_id, array['admin','manager','staff'])
    or is_guest_for_hotel(hotel_id)
  );

drop policy if exists "opening_hours write" on opening_hours;
create policy "opening_hours write" on opening_hours
  for all
  using (can_manage_content(hotel_id))
  with check (can_manage_content(hotel_id));

-- transport_links
alter table transport_links enable row level security;
alter table transport_links force row level security;

drop policy if exists "transport_links read" on transport_links;
create policy "transport_links read" on transport_links
  for select
  using (
    is_service_role()
    or has_role(hotel_id, array['admin','manager','staff'])
    or is_guest_for_hotel(hotel_id)
  );

drop policy if exists "transport_links write" on transport_links;
create policy "transport_links write" on transport_links
  for all
  using (can_manage_content(hotel_id))
  with check (can_manage_content(hotel_id));

-- weather_snapshots
alter table weather_snapshots enable row level security;
alter table weather_snapshots force row level security;

drop policy if exists "weather_snapshots read" on weather_snapshots;
create policy "weather_snapshots read" on weather_snapshots
  for select
  using (
    is_service_role()
    or has_role(hotel_id, array['admin','manager','staff'])
    or is_guest_for_hotel(hotel_id)
  );

-- annonces
alter table announcements enable row level security;
alter table announcements force row level security;

drop policy if exists "announcements read" on announcements;
create policy "announcements read" on announcements
  for select
  using (
    is_service_role()
    or has_role(hotel_id, array['admin','manager','staff'])
    or is_guest_for_hotel(hotel_id)
  );

drop policy if exists "announcements write" on announcements;
create policy "announcements write" on announcements
  for all
  using (can_manage_content(hotel_id))
  with check (can_manage_content(hotel_id));

alter table announcement_targets enable row level security;
alter table announcement_targets force row level security;

drop policy if exists "announcement_targets manage" on announcement_targets;
create policy "announcement_targets manage" on announcement_targets
  for all
  using (is_service_role() or has_role((select hotel_id from announcements where id = announcement_id), array['admin','manager']))
  with check (is_service_role() or has_role((select hotel_id from announcements where id = announcement_id), array['admin','manager']));

-- activities
alter table activities enable row level security;
alter table activities force row level security;

drop policy if exists "activities read" on activities;
create policy "activities read" on activities
  for select
  using (
    is_service_role()
    or has_role(hotel_id, array['admin','manager','staff'])
    or is_guest_for_hotel(hotel_id)
  );

drop policy if exists "activities write" on activities;
create policy "activities write" on activities
  for all
  using (can_manage_content(hotel_id))
  with check (can_manage_content(hotel_id));

-- =========================
-- Messagerie
-- =========================

alter table chat_threads enable row level security;
alter table chat_threads force row level security;

drop policy if exists "chat_threads staff" on chat_threads;
create policy "chat_threads staff" on chat_threads
  for all
  using (is_service_role() or has_role(hotel_id, array['admin','manager','staff']))
  with check (is_service_role() or has_role(hotel_id, array['admin','manager','staff']));

drop policy if exists "chat_threads guests" on chat_threads;
create policy "chat_threads guests" on chat_threads
  for select
  using (stay_id is not null and is_guest_for_stay(stay_id));

alter table thread_participants enable row level security;
alter table thread_participants force row level security;

drop policy if exists "thread_participants staff" on thread_participants;
create policy "thread_participants staff" on thread_participants
  for all
  using (is_service_role() or has_role((select hotel_id from chat_threads where id = thread_id), array['admin','manager','staff']))
  with check (is_service_role() or has_role((select hotel_id from chat_threads where id = thread_id), array['admin','manager','staff']));

drop policy if exists "thread_participants guests" on thread_participants;
create policy "thread_participants guests" on thread_participants
  for select
  using (
    participant_type = 'guest'
    and guest_id = current_guest_id()
  );

alter table chat_messages enable row level security;
alter table chat_messages force row level security;

drop policy if exists "chat_messages staff" on chat_messages;
create policy "chat_messages staff" on chat_messages
  for all
  using (is_service_role() or has_role(hotel_id, array['admin','manager','staff']))
  with check (is_service_role() or has_role(hotel_id, array['admin','manager','staff']));

drop policy if exists "chat_messages guests" on chat_messages;
create policy "chat_messages guests" on chat_messages
  for all
  using (
    author_type = 'guest' and guest_id = current_guest_id()
    or (thread_id in (select id from chat_threads where stay_id is not null and is_guest_for_stay(stay_id)))
  )
  with check (
    author_type <> 'guest' or guest_id = current_guest_id()
  );

alter table quick_replies enable row level security;
alter table quick_replies force row level security;

drop policy if exists "quick_replies staff" on quick_replies;
create policy "quick_replies staff" on quick_replies
  for all
  using (is_service_role() or has_role(hotel_id, array['admin','manager','staff']))
  with check (is_service_role() or has_role(hotel_id, array['admin','manager']));

-- =========================
-- Commandes & services
-- =========================

alter table service_catalogs enable row level security;
alter table service_catalogs force row level security;

drop policy if exists "service_catalogs read" on service_catalogs;
create policy "service_catalogs read" on service_catalogs
  for select
  using (
    is_service_role()
    or has_role(hotel_id, array['admin','manager','staff'])
    or is_guest_for_hotel(hotel_id)
  );

drop policy if exists "service_catalogs write" on service_catalogs;
create policy "service_catalogs write" on service_catalogs
  for all
  using (is_service_role() or has_role(hotel_id, array['admin','manager']))
  with check (is_service_role() or has_role(hotel_id, array['admin','manager']));

alter table service_items enable row level security;
alter table service_items force row level security;

drop policy if exists "service_items read" on service_items;
create policy "service_items read" on service_items
  for select
  using (
    is_service_role()
    or has_role(hotel_id, array['admin','manager','staff'])
    or is_guest_for_hotel(hotel_id)
  );

drop policy if exists "service_items write" on service_items;
create policy "service_items write" on service_items
  for all
  using (is_service_role() or has_role(hotel_id, array['admin','manager']))
  with check (is_service_role() or has_role(hotel_id, array['admin','manager']));

alter table service_options enable row level security;
alter table service_options force row level security;

drop policy if exists "service_options manage" on service_options;
create policy "service_options manage" on service_options
  for all
  using (is_service_role() or has_role((select hotel_id from service_items where id = service_item_id), array['admin','manager']))
  with check (is_service_role() or has_role((select hotel_id from service_items where id = service_item_id), array['admin','manager']));

alter table catalog_roles enable row level security;
alter table catalog_roles force row level security;

drop policy if exists "catalog_roles manage" on catalog_roles;
create policy "catalog_roles manage" on catalog_roles
  for all
  using (is_service_role() or has_role((select hotel_id from service_catalogs where id = catalog_id), array['admin','manager']))
  with check (is_service_role() or has_role((select hotel_id from service_catalogs where id = catalog_id), array['admin','manager']));

alter table tags enable row level security;
alter table tags force row level security;

drop policy if exists "tags read" on tags;
create policy "tags read" on tags
  for select
  using (is_service_role() or has_role(hotel_id, array['admin','manager','staff']));

drop policy if exists "tags write" on tags;
create policy "tags write" on tags
  for all
  using (is_service_role() or has_role(hotel_id, array['admin','manager']))
  with check (is_service_role() or has_role(hotel_id, array['admin','manager']));

alter table service_item_tags enable row level security;
alter table service_item_tags force row level security;

drop policy if exists "service_item_tags manage" on service_item_tags;
create policy "service_item_tags manage" on service_item_tags
  for all
  using (is_service_role() or has_role((select hotel_id from service_items where id = service_item_id), array['admin','manager']))
  with check (is_service_role() or has_role((select hotel_id from service_items where id = service_item_id), array['admin','manager']));

alter table transport_partners enable row level security;
alter table transport_partners force row level security;

drop policy if exists "transport_partners read" on transport_partners;
create policy "transport_partners read" on transport_partners
  for select
  using (
    is_service_role()
    or has_role(hotel_id, array['admin','manager','staff'])
    or is_guest_for_hotel(hotel_id)
  );

drop policy if exists "transport_partners write" on transport_partners;
create policy "transport_partners write" on transport_partners
  for all
  using (is_service_role() or has_role(hotel_id, array['admin','manager']))
  with check (is_service_role() or has_role(hotel_id, array['admin','manager']));

alter table orders enable row level security;
alter table orders force row level security;

drop policy if exists "orders staff" on orders;
create policy "orders staff" on orders
  for all
  using (is_service_role() or has_role(hotel_id, array['admin','manager','staff']))
  with check (is_service_role() or has_role(hotel_id, array['admin','manager','staff']));

drop policy if exists "orders guests" on orders;
create policy "orders guests" on orders
  for all
  using (is_guest_for_stay(stay_id))
  with check (is_guest_for_stay(stay_id));

alter table order_items enable row level security;
alter table order_items force row level security;

drop policy if exists "order_items staff" on order_items;
create policy "order_items staff" on order_items
  for all
  using (is_service_role() or has_role((select hotel_id from orders where id = order_id), array['admin','manager','staff']))
  with check (is_service_role() or has_role((select hotel_id from orders where id = order_id), array['admin','manager','staff']));

drop policy if exists "order_items guests" on order_items;
create policy "order_items guests" on order_items
  for all
  using (is_guest_for_stay((select stay_id from orders where id = order_id)))
  with check (is_guest_for_stay((select stay_id from orders where id = order_id)));

alter table order_item_options enable row level security;
alter table order_item_options force row level security;

drop policy if exists "order_item_options staff" on order_item_options;
create policy "order_item_options staff" on order_item_options
  for all
  using (is_service_role() or has_role((select hotel_id from orders where id = (select order_id from order_items where id = order_item_id)), array['admin','manager','staff']))
  with check (is_service_role() or has_role((select hotel_id from orders where id = (select order_id from order_items where id = order_item_id)), array['admin','manager','staff']));

drop policy if exists "order_item_options guests" on order_item_options;
create policy "order_item_options guests" on order_item_options
  for all
  using (is_guest_for_stay((select stay_id from orders where id = (select order_id from order_items where id = order_item_id))))
  with check (is_guest_for_stay((select stay_id from orders where id = (select order_id from order_items where id = order_item_id))));

alter table order_assignments enable row level security;
alter table order_assignments force row level security;

drop policy if exists "order_assignments staff" on order_assignments;
create policy "order_assignments staff" on order_assignments
  for all
  using (is_service_role() or has_role((select hotel_id from orders where id = order_id), array['admin','manager','staff']))
  with check (is_service_role() or has_role((select hotel_id from orders where id = order_id), array['admin','manager','staff']));

alter table order_status_history enable row level security;
alter table order_status_history force row level security;

drop policy if exists "order_status_history staff" on order_status_history;
create policy "order_status_history staff" on order_status_history
  for select
  using (is_service_role() or has_role((select hotel_id from orders where id = order_id), array['admin','manager','staff']));

drop policy if exists "order_status_history guests" on order_status_history;
create policy "order_status_history guests" on order_status_history
  for select
  using (is_guest_for_stay((select stay_id from orders where id = order_id)));

-- =========================
-- Support & observabilité
-- =========================

alter table audit_logs enable row level security;
alter table audit_logs force row level security;

drop policy if exists "audit_logs staff" on audit_logs;
create policy "audit_logs staff" on audit_logs
  for select
  using (is_service_role() or has_role(hotel_id, array['admin','manager']));

drop policy if exists "audit_logs service" on audit_logs;
create policy "audit_logs service" on audit_logs
  for all
  using (is_service_role())
  with check (is_service_role());

alter table analytics_events enable row level security;
alter table analytics_events force row level security;

drop policy if exists "analytics_events staff" on analytics_events;
create policy "analytics_events staff" on analytics_events
  for select
  using (is_service_role() or has_role(hotel_id, array['admin','manager','staff']));

drop policy if exists "analytics_events service" on analytics_events;
create policy "analytics_events service" on analytics_events
  for all
  using (is_service_role())
  with check (is_service_role());
