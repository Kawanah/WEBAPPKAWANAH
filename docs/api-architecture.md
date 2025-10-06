# API Architecture — Kawanah MVP

## 1. Stack & Principes
- **Runtime** : Node.js 20 LTS.
- **Framework** : NestJS (modulaire, TS-first, DI, tests). Alternative possible (Express + Zod/Router) mais Nest facilite structure CLEAR.
- **ORM/Client DB** : Supabase JS client + PostgREST pour opérations simples ; Prisma optionnel si besoin d’abstraction. RLS activé donc JWT service-role requis côté back-office.
- **Auth & sessions** : Supabase Auth pour staff (email/password magic link) + JWT signés. Pour voyageurs : jeton QR (JWT signé par backend) échangeable contre session “guest”.
- **Deployment** : API en mode stateless (Render). Secrets gérés via `.env` + Vault (CLEAR).
- **Observabilité** : Pino + OpenTelemetry exporter, envoi vers log aggregator.

## 2. Modules principaux
| Module | Rôle | Notes |
|---|---|---|
| `AuthModule` | Login staff, session guest via QR, rafraîchissement token | Interagit avec Supabase Auth (service-role). Gère RBAC et injection claims (hotel_id, role). |
| `HotelsModule` | Infos établissement, contenus, météo, activités | Orchestration de tables `info_pages`, `practical_info_*`, `weather_snapshots`. Cache 5 min. |
| `MessagingModule` | Threads, participants, messages, quick replies | Subscribe Supabase Realtime pour push events ; API REST + WebSocket fallback. |
| `OrdersModule` | Catalogues, commandes, statuts, affectations | Règles métiers (états, notifications). Intégration pipeline facture (déferred). |
| `SupportModule` | Audit logs, analytics export | Access admin/manager only. |
| `CommonModule` | Middlewares (RBAC, hotel resolver), interceptors (CLEAR) | Contient filtres d’erreurs normalisés. |

## 3. Authentification & Autorisation (CLEAR)
- **Staff**
  1. POST `/auth/staff/login` → délégué à Supabase Auth (`signInWithPassword`).
  2. Backend vérifie `user_roles` et renvoie JWT applicatif (claims : `hotel_id`, `role`, `staff_id`).
  3. Middleware `StaffGuard` valide JWT, hydrate `request.user`.
- **Voyageurs**
  1. QR contient `token` signé (payload : `stay_id`, `hotel_id`, `exp`).
  2. POST `/auth/guest/qr` : valide signature, appelle Supabase pour récupérer contexte, génère JWT guest (durée courte, rafraîchi). Pas de compte Supabase obligatoire.
- **RBAC**
  - Decorator `@Roles('admin','manager')` + guard compare à `request.user.roles`.
  - Pour guest : `GuestGuard` vérifie `stay_id` sur les routes.
- **Interaction Supabase**
  - Staff endpoints -> utiliser service-role (via Supabase client) pour bypass RLS si nécessaire, ou s’appuyer sur RLS + JWT claims en mode end-user.
  - Guest endpoints -> passer JWT guest signé par backend + clé anon.

## 4. Endpoints Feature 1 — Informations & Messagerie
### 4.1 Informations pratiques
- `GET /v1/hotels/:hotelId/info` → agrège pages, sections, horaires, transports, météo (cache). Rôles : staff/guest hôtel.
- `PUT /v1/hotels/:hotelId/info/pages/:pageId` → staff `manager+`.
- `POST /v1/hotels/:hotelId/announcements` → staff `manager+`.
- `GET /v1/hotels/:hotelId/announcements` → staff & guests.
- `GET /v1/stays/:stayId/dashboard` → vue voyageur (pages filtrées, annonces actives, activités). Guard : `GuestGuard`.

### 4.2 Messagerie temps réel
- `GET /v1/stays/:stayId/threads` → liste threads voyageur (guest). Staff utilisent `/v1/hotels/:hotelId/threads?status=open`.
- `POST /v1/threads` → créer thread (guest ou staff). Body : `stayId`, `subject`, `firstMessage`.
- `POST /v1/threads/:threadId/messages` → message texte + pièces jointes (S3 presign).
- `PATCH /v1/threads/:threadId` → changement statut (staff).
- **Realtime** : canal Supabase `chat_messages:thread_id=eq.<id>` consommé côté front. API émet websockets fallback si besoin.

## 5. Endpoints Feature 2 — Commandes Room Service & Transport
### 5.1 Catalogues & services
- `GET /v1/hotels/:hotelId/catalogs?type=room_service` → staff & guests.
- `POST /v1/hotels/:hotelId/catalogs` → staff `manager+`.
- `POST /v1/catalogs/:catalogId/items` → staff `manager+`.
- `PATCH /v1/items/:itemId/status` → staff (disponibilité).
- `GET /v1/hotels/:hotelId/transport-partners` → staff & guests.

### 5.2 Commandes & suivi
- `POST /v1/stays/:stayId/orders` → guest ou staff (room charge). Body : `items[]`, `notes`, `scheduledAt`.
- `GET /v1/stays/:stayId/orders` → guest (historique séjour).
- `GET /v1/hotels/:hotelId/orders?status=pending` → staff.
- `PATCH /v1/orders/:orderId/status` → staff (transition validée business rules).
- `POST /v1/orders/:orderId/assign` → staff (affectation).
- `GET /v1/orders/:orderId/timeline` → staff/guest (suivi status_history).

## 6. Middlewares & Observabilité
- **Request logging** via Pino (corrélation `requestId`).
- **Rate limiting** (express-rate-limit) sur endpoints publics (`auth/guest`).
- **Validation** via `class-validator`/`Zod` (payloads, CLEAR).
- **Error filter** standardise codes (`KAW-001` etc.).
- **Metrics** : `prom-client` (latence, taux succès) export `/metrics` (auth service-role seulement).

## 7. Testing CLEAR
- **Unit tests** : services (Nest `TestingModule`), mocks Supabase client via `@supabase/supabase-js` stub.
- **Integration** : Supertest sur endpoints critiques (auth, orders, messaging) avec base Supabase locale (`supabase start`). Fixtures alignées sur seed minimal.
- **Contract tests** : optionally, schema OpenAPI généré via `@nestjs/swagger`.

## 8. Roadmap de livraison API
1. `AuthModule` + guards staff/guest + intégration Supabase (CLEAR Gate Auth).
2. `HotelsModule` (GET dashboard, CRUD contenu) + tests. Gate "API Core".
3. `MessagingModule` (threads/messages) + realtime configuration.
4. `OrdersModule` (catalogue + commandes + transitions) + business rules.
5. Observabilité + Support module (audit exports).
6. Harden RLS + tests e2e (Cypress API) avant release MVP.

## 9. Notes Sécurité & Compliance
- JWT staff signés HS512, TTL court (2h) + refresh.
- JWT guest TTL 1h, renouvellé via QR + check `stay.status`.
- Toutes les écritures auditables (`audit_logs` via interceptor).
- Données sensibles chiffrées au repos (Supabase gère TDE ; s’assurer champs critiques pseudo-anonymisés si export).
- Webhooks channel manager/ PMS : prévoir module isolé + IP allowlist + signature.

