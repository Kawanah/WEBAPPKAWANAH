# Supabase Schema — Features 1 & 2

## 1. Vue d’ensemble
- Multi-tenant : chaque ressource est rattachée à `hotel_id`. Les voyageurs sont reliés à un séjour (`stay_id`) créé via QR code.
- Auth : staff lié à `auth.users` via `staff_profiles`, voyageurs via `guest_profiles`/`stay_guests`. Les rôles RBAC sont gérés dans `roles` + `user_roles`.
- Realtime : `chat_messages`, `orders`, `order_status_history`, `weather_snapshots` publient les changements via Supabase Realtime.

Diagramme texte (principales relations) :
```
 hotels ─┬─< rooms ─┬─< stays ─┬─< stay_guests >─ guest_profiles
        │          │         ├─< chat_threads ─┬─< thread_participants ─ staff_profiles
        │          │         │                 └─< chat_messages
        │          │         └─< orders ─┬─< order_items ─┬─< order_item_options >─ service_options
        │          │                      ├─< order_assignments >─ staff_profiles
        │          │                      └─< order_status_history
        │          └─< room_qr_codes
        ├─< staff_profiles ─┬─ user_roles >─ roles
        ├─< info_pages ─┬─< practical_info_sections ─┬─< practical_info_items
        │               ├─< opening_hours
        │               └─< transport_links
        ├─< announcement_targets >─ announcements
        ├─< weather_snapshots
        ├─< activities
        ├─< service_catalogs ─┬─< service_items ─┬─< service_options
        │                     │               └─< service_item_tags >─ tags
        │                     └─< catalog_roles >─ roles
        └─< transport_partners
```

## 2. Entités cœur (structure & utilisateurs)
### 2.1 hotels
- `id` (uuid, pk)
- `name`, `slug`, `address`, `timezone`
- `settings` (jsonb : devise, préférences chatbot, intégrations)
- `created_at`, `updated_at`

### 2.2 rooms
- `id` (uuid, pk)
- `hotel_id` (fk → hotels)
- `label`, `floor`, `capacity`
- `metadata` (jsonb)
- `is_active`
- timestamps

### 2.3 stays
- `id` (uuid, pk)
- `hotel_id`
- `room_id`
- `check_in`, `check_out`
- `primary_guest_id` (fk → guest_profiles, nullable)
- `qr_code_id` (fk → room_qr_codes)
- `status` (`booked`, `checked_in`, `checked_out`, `cancelled`)
- `created_at`

### 2.4 stay_guests (table de jointure)
- `id`
- `stay_id` (fk → stays)
- `guest_id` (fk → guest_profiles)
- `role` (`primary`, `secondary`)
- `invited_at`
- `added_by` (fk → staff_profiles)
- Contrainte d’unicité `(stay_id, guest_id)`

### 2.5 room_qr_codes
- `id`
- `hotel_id`
- `room_id`
- `token` (unique)
- `expires_at` (optionnel)
- `created_at`

### 2.6 staff_profiles
- `id`
- `hotel_id`
- `user_id` (fk → auth.users)
- `full_name`, `email`, `phone`
- `position`
- `created_at`, `updated_at`

### 2.7 guest_profiles
- `id`
- `hotel_id`
- `auth_user_id` (fk → auth.users, nullable pour guests anonymes)
- `full_name`, `email`, `phone`
- `preferred_language`
- `created_at`

### 2.8 roles & user_roles (table de jointure)
- `roles` : `id`, `code` (`admin`, `manager`, `staff`, `guest`), `description`
- `user_roles` : `id`, `hotel_id`, `user_id` (fk → auth.users), `role_id`, `assigned_by`, `created_at` (contrainte `(hotel_id, user_id, role_id)` unique)

## 3. Contenus, infos pratiques & météo
### 3.1 info_pages
- `id`
- `hotel_id`
- `title`, `slug`
- `content` (jsonb rich-text/CTA)
- `visibility` (`public`, `staff_only`)
- `updated_by`
- `updated_at`

### 3.2 practical_info_sections
- `id`
- `hotel_id`
- `title`
- `description`
- `sort_order`
- `icon`

### 3.3 practical_info_items
- `id`
- `section_id`
- `hotel_id`
- `label`
- `value`
- `details` (text/json)
- `info_type` (`schedule`, `contact`, `amenity`, `faq`, etc.)
- `icon`
- `sort_order`

### 3.4 opening_hours
- `id`
- `hotel_id`
- `section_id` (optionnel)
- `service_name`
- `day_of_week` (0–6)
- `open_time`, `close_time`
- `notes`

### 3.5 transport_links
- `id`
- `hotel_id`
- `type` (`bus`, `metro`, `taxi`, `shuttle`)
- `name`
- `description`
- `contact`
- `booking_url`
- `schedule` (jsonb)
- `is_active`

### 3.6 weather_snapshots
- `id`
- `hotel_id`
- `source`
- `payload` (jsonb : température, conditions, prévisions)
- `fetched_at`
- `valid_until`

### 3.7 announcements
- `id`
- `hotel_id`
- `title`
- `body`
- `start_at`, `end_at`
- `priority`
- `created_by`
- timestamps

### 3.8 announcement_targets (table de jointure)
- `id`
- `announcement_id`
- `target_type` (`role`, `room`, `stay`)
- `target_id` (fk polymorphe : `roles`, `rooms`, `stays`)
- `created_at`

### 3.9 activities
- `id`
- `hotel_id`
- `title`
- `description`
- `location`
- `start_at`, `end_at`
- `capacity`
- `booking_required`
- `created_by`
- timestamps

## 4. Messagerie (Feature 1)
### 4.1 chat_threads
- `id`
- `hotel_id`
- `stay_id`
- `initiated_by`
- `subject`
- `status` (`open`, `pending`, `closed`)
- `created_at`, `updated_at`

### 4.2 thread_participants (table de jointure)
- `id`
- `thread_id`
- `participant_type` (`guest`, `staff`)
- `participant_id` (fk → `stay_guests` ou `staff_profiles`)
- `role` (`owner`, `assignee`, `observer`)
- `joined_at`
- `left_at`

### 4.3 chat_messages
- `id`
- `thread_id`
- `hotel_id`
- `author_type`
- `author_id`
- `body`
- `attachments` (jsonb)
- `sent_at`
- `read_at`
- `metadata`

### 4.4 quick_replies
- `id`
- `hotel_id`
- `label`
- `body`
- `category`
- `created_by`
- timestamps

## 5. Commandes room-service & transport (Feature 2)
### 5.1 service_catalogs
- `id`
- `hotel_id`
- `type` (`room_service`, `transport`)
- `title`
- `description`
- `is_active`
- timestamps

### 5.2 service_items
- `id`
- `catalog_id`
- `hotel_id`
- `name`
- `description`
- `price`
- `currency`
- `preparation_time_minutes`
- `is_available`
- `options_schema` (jsonb)
- `created_by`
- `updated_at`

### 5.3 service_options
- `id`
- `service_item_id`
- `label`
- `additional_price`
- `metadata`

### 5.4 catalog_roles (table de jointure)
- `id`
- `catalog_id`
- `role_id` (fk → roles)
- `access_level` (`manage`, `view`)
- `created_at`

### 5.5 tags
- `id`
- `hotel_id`
- `code`
- `label`
- `category`
- `color`

### 5.6 service_item_tags (table de jointure)
- `id`
- `service_item_id`
- `tag_id`
- `created_at`

### 5.7 transport_partners
- `id`
- `hotel_id`
- `name`
- `contact`
- `notes`
- `is_active`

### 5.8 orders
- `id`
- `hotel_id`
- `stay_id`
- `catalog_id`
- `requested_for`
- `scheduled_at`
- `status`
- `total_amount`
- `currency`
- `created_by` (guest/staff)
- `created_at`, `updated_at`

### 5.9 order_items
- `id`
- `order_id`
- `service_item_id`
- `quantity`
- `unit_price`
- `options` (jsonb)
- `notes`

### 5.10 order_item_options (table de jointure)
- `id`
- `order_item_id`
- `service_option_id`
- `price_delta`
- `selected_at`

### 5.11 order_assignments (table de jointure)
- `id`
- `order_id`
- `staff_id` (fk → staff_profiles)
- `assigned_role` (`kitchen`, `delivery`, `driver`...)
- `assigned_at`
- `unassigned_at`

### 5.12 order_status_history
- `id`
- `order_id`
- `from_status`
- `to_status`
- `changed_by`
- `changed_at`
- `comment`

### 5.13 invoices (future intégration)
- `id`
- `stay_id`
- `total_amount`
- `currency`
- `status`
- `export_reference`
- `issued_at`

## 6. Support & Observabilité
### 6.1 audit_logs
- `id`
- `hotel_id`
- `actor_type`
- `actor_id`
- `action`
- `entity`
- `entity_id`
- `metadata`
- `created_at`

### 6.2 analytics_events
- `id`
- `hotel_id`
- `stay_id`
- `event_type`
- `payload`
- `occurred_at`

## 7. Multi-tenant & RLS
- `hotel_id` présent partout (sauf `roles`, `tags` éventuellement global).
- RLS staff : filtre sur `hotel_id` + rôle (admin complet, manager restreint, staff opérationnel).
- RLS voyageurs : accès via `stay_guests` + QR token (lecture des infos, écriture limitée aux commandes/messages de leur séjour).
- Services système : policies dédiées (clé de service Supabase) pour webhooks/bots/meteo.
- Tables sensibles (`orders`, `chat_messages`, `audit_logs`, `weather_snapshots`) peuvent utiliser fonctions `SECURITY DEFINER` pour opérations server-side.

## 8. Triggers & Realtime
- Realtime : `chat_messages`, `orders`, `order_status_history`, `weather_snapshots`.
- `orders_total` : recalcul `total_amount` lors des changements `order_items`/`order_item_options`.
- `orders_status_change()` : insertion auto dans `order_status_history`.
- `stay_checkout_close_threads` : ferme les threads open quand `stays.status` passe à `checked_out`.
- `weather_cleanup` : purge des snapshots expirés.

## 9. Seeds & Fixtures
- Rôles (`admin`, `manager`, `staff`, `guest`).
- Sections info par défaut (horaires accueil, wifi, numéros d’urgence, transports).
- Quick replies FAQ.
- Catalogues room service & taxi + tags d’exemple.
- Jeu de données météo simulé.
- Staff démo et stays fictifs pour tests e2e.

## 10. Backlog ouvert
- Réservations d’activités (feature 3) via tables `activity_slots`, `activity_bookings`.
- `bot_responses` pour enrichir le chatbot FAQ.
- Fonctions edge Supabase pour synchronisation météo programmée.
- Intégration `invoices` avec système hôtelier externe.
