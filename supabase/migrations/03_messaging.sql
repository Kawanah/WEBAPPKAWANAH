-- Migration 03_messaging : messagerie temps réel (threads, participants, messages, quick replies)

create table if not exists chat_threads (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    stay_id uuid references stays(id) on delete set null,
    initiated_by text not null check (initiated_by in ('guest','staff')),
    subject text,
    status text not null default 'open' check (status in ('open','pending','closed')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index if not exists chat_threads_hotel_idx on chat_threads(hotel_id);
create index if not exists chat_threads_stay_idx on chat_threads(stay_id);

create table if not exists thread_participants (
    id uuid primary key default gen_random_uuid(),
    thread_id uuid not null references chat_threads(id) on delete cascade,
    participant_type text not null check (participant_type in ('guest','staff')),
    guest_id uuid references stay_guests(id) on delete cascade,
    staff_id uuid references staff_profiles(id) on delete cascade,
    role text not null default 'observer' check (role in ('owner','assignee','observer')),
    joined_at timestamptz not null default now(),
    left_at timestamptz,
    constraint thread_participants_consistency check (
        (participant_type = 'guest' and guest_id is not null and staff_id is null) or
        (participant_type = 'staff' and staff_id is not null and guest_id is null)
    ),
    constraint thread_participants_unique unique (thread_id, participant_type, coalesce(guest_id, staff_id))
);
create index if not exists thread_participants_thread_idx on thread_participants(thread_id);

create table if not exists chat_messages (
    id uuid primary key default gen_random_uuid(),
    thread_id uuid not null references chat_threads(id) on delete cascade,
    hotel_id uuid not null references hotels(id) on delete cascade,
    author_type text not null check (author_type in ('guest','staff','bot')),
    guest_id uuid references stay_guests(id) on delete set null,
    staff_id uuid references staff_profiles(id) on delete set null,
    body text not null,
    attachments jsonb not null default '[]',
    metadata jsonb not null default '{}',
    sent_at timestamptz not null default now(),
    read_at timestamptz,
    constraint chat_messages_author_consistency check (
        (author_type = 'guest' and guest_id is not null and staff_id is null) or
        (author_type = 'staff' and staff_id is not null and guest_id is null) or
        (author_type = 'bot' and guest_id is null and staff_id is null)
    )
);
create index if not exists chat_messages_thread_idx on chat_messages(thread_id);
create index if not exists chat_messages_hotel_idx on chat_messages(hotel_id);
create index if not exists chat_messages_sent_idx on chat_messages(sent_at);

create table if not exists quick_replies (
    id uuid primary key default gen_random_uuid(),
    hotel_id uuid not null references hotels(id) on delete cascade,
    label text not null,
    body text not null,
    category text,
    created_by uuid references staff_profiles(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index if not exists quick_replies_hotel_idx on quick_replies(hotel_id);

-- Triggers updated_at
create trigger chat_threads_set_updated_at
before update on chat_threads
for each row execute function set_updated_at();

create trigger quick_replies_set_updated_at
before update on quick_replies
for each row execute function set_updated_at();
