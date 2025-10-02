# Kawanah MVP Guidelines

## 1. Vision & Success Metrics
- Offrir aux voyageurs un compagnon numérique via QR code, sans installation, pour consulter les informations clés du séjour et échanger avec l'hébergeur.
- Simplifier la prise de commande room-service et transport avec facturation centralisée sur la note de chambre.
- Indicateurs à suivre dès le MVP : taux d'hôtels équipés, taux d'adoption du QR code, nombre de réservations via l'app, taux d'adoption par chambre occupée.

## 2. Personas & Parcours Cibles
- Voyageur : scanne un QR, accède aux informations pratiques de l'établissement, consulte les actus et contacte l'équipe via chat.
- Staff hébergeur : met à jour les contenus, suit les conversations, traite les commandes, valide la facturation de check-out.

## 3. Périmètre Fonctionnel MVP
### Feature 1 — Accès aux informations & messagerie
- Tableau de bord voyageur avec infos statiques (horaires, services, météo, transports) et mises à jour dynamiques (annonces, activités du jour).
- Calendrier des activités/animations affiché en lecture seule, administré par l'hébergeur.
- Messagerie temps réel voyageur ↔ hébergeur, avec notifications, historique par session de séjour et réponses prédéfinies pour FAQ.
- Interface back-office simple pour que le staff gère contenus, planning et messages.

### Feature 2 — Commandes room service & transport
- Catalogue de services room service et transports, configuré par l'hébergeur (produits, descriptions, disponibilité, SLA).
- Prise de commande en quelques étapes : sélection, options, confirmation, suivi de statut.
- Traitement côté staff : console de suivi en temps réel, changement de statut (reçu, en cours, livré, annulé), assignation éventuelle.
- Agrégation des commandes à la note de chambre/emplacement ; export vers le système de facturation interne lors du check-out.

## 4. Exigences Non Fonctionnelles
- Disponibilité : service cloud (SLA interne ≥ 99,5 %), déploiement blue/green ou rollbacks rapides.
- Performance : chargement initial mobile < 2 s sur 4G, interactions clés < 300 ms.
- Sécurité & confidentialité : authentification staff forte, sessions voyageur limitées au séjour, chiffrement TLS, conformité RGPD (logs, consentement).
- Observabilité : journalisation structurée, traçabilité des commandes et messages, monitoring des métriques produit.
- Accessibilité : respecter WCAG AA sur la webapp voyageur.

## 5. Design System & Méthode CLEAR
### 5.1 Foundations
- **Couleurs** : Primary `#1D4ED8`, Secondary `#FF6638`, Success `#10B981`, Warning `#F59E0B`, Error `#EF4444`, neutres `#111827`, `#6B7280`, `#F3F4F6`, `#FFFFFF`.
- **Typographies** : titres Inter Bold, texte Inter Regular, code Roboto Mono.
- **Grille & espacements** : système 8px, grille responsive 12 colonnes.
- **Iconographie** : style outline (Lucide/Feather) en 24px.
- **Effets** : radius 8px (12px modales), ombres sm/md/lg selon profondeur.

### 5.2 Composants UI
- **Boutons** : primary, secondary, ghost avec états hover/active/disabled.
- **Formulaires** : inputs bordures `#D1D5DB`, focus Primary, error Error.
- **Cartes & modales** : fond blanc, ombres légères, padding 16px.
- **Alertes & badges** : variations Success/Warning/Error/Info.
- **Navigation & tableaux** : header + sidebar, tabs soulignés Primary, tableaux avec header gris clair et hover léger.
- **Dashboard widgets** : cartes titres/valeurs, graphiques cohérents.

### 5.3 Guidelines d’usage
- Ton professionnel, simple, accessible ; contraste ≥ 4.5:1 ; labels explicites ; mobile-first avec breakpoints 640/768/1024/1280.
- Layouts flex/grid ; positionnement absolu/fixe seulement si indispensable.
- Architecture : composants réutilisables, logique métier séparée, fichiers concis (ui dans `/components/ui`, métier dans `/components`, utilitaires `/utils`, hooks `/hooks`, types `/types`).

### 5.4 Méthode CLEAR
- **C**lean : code lisible, structuré, revues de code systématiques et refactorings continus par petites itérations.
- **L**ogic : logique métier isolée, testable, couverte par des tests unitaires/intégration.
- **E**fficient : performance optimisée (chargements Next.js, requêtes SQL, realtime Supabase) et monitoring de la consommation.
- **A**ccessible : respect des critères WCAG et design inclusif.
- **R**esponsive : adaptation multi-device, tests sur breakpoints clés.

## 6. Modèle de Données (à affiner)
- Entités clés : établissement, chambre/emplacement, séjour (check-in/out, QR), voyageur (anonyme ou identifié), contenu informatif, activité, session de chat, message, commande, ligne de commande, catalogue service, statut de commande, rôle utilisateur (administrateur, manager, employé, voyageur).
- Relations : un séjour ↔ plusieurs commandes et threads de messages ; un catalogue ↔ plusieurs établissements (gérer variantes).
- Gestion du temps réel : horodatage et suivi des statuts, traçabilité des transitions.

## 7. Choix Techniques Validés
- Frontend voyageur & backoffice : Next.js/React avec Tailwind CSS aligné avec le design system.
- Authentification & rôles : Node.js + RBAC (admin, manager, employé, voyageur), sessions QR pour voyageurs.
- Backend API : Node.js (framework à préciser) exposant REST/GraphQL, reliant DB, realtime et commandes.
- Base de données : Supabase (PostgreSQL) pour toutes les entités et stockage des messages/realtime.
- Messagerie temps réel : Supabase Realtime synchronisant chat et statuts commandes.
- Facturation : agrégation interne sur note de chambre, sans passerelle de paiement pour le MVP.
- Infrastructure & déploiement : Render (ou équivalent PaaS) pour Next.js + API Node.js, Supabase cloud managé.
- Gestion des secrets/config : `.env` chiffrés + coffre (SOPS/Doppler) adapté au PaaS.

## 8. Processus & Qualité
### 8.1 CLEAR Gates
- **Auth & RBAC** — Checklist : tests unitaires/intégration login + refresh, mapping RBAC validé, politiques Supabase revues, scan dépendances, tolérance brute-force testée, audit accessibilité écrans auth, journalisation événements de sécurité vérifiée. Responsables : dev backend (implémentation + tests), reviewer sécurité (RBAC + politiques), product/QA (parcours utilisateur).
- **API Core & Contenus** — Checklist : schémas/contrats API documentés, tests e2e sur endpoints critiques, gestion erreurs standardisée, quotas/rate-limiting configurés, logs + métriques exposés, conformité RGPD (données perso minimisées). Responsables : lead backend (tests + docs), devops (observabilité + rate-limit), PO/QA (conformité données).
- **UI Voyageur & Backoffice** — Checklist : conformité design system (composants partagés), responsive vérifié sur breakpoints, contrastes/a11y validés, états de chargement/erreur couverts, analytics/événements branchés. Responsables : dev front (implémentation), designer/PO (validation visuelle), QA (tests responsive/a11y).
- **Commandes & Facturation** — Checklist : transitions statuts testées (unitaires + e2e), agrégation note chambre contrôlée, messages realtime cohérents, scénarios erreur (annulation, rupture stock) couverts, exports check-out vérifiés. Responsables : dev feature (logic), reviewer finance/ops (process facturation), QA (scénarios négatifs).
- **Déploiement & Observabilité** — Checklist : pipeline Render vert (lint, tests, build), migrations Supabase validées sur staging, monitoring/alarmes actifs, sauvegarde/restaure testée, documentation ops mise à jour. Responsables : devops/lead tech (pipelines + monitoring), DBA (migrations), support (procédures incident).

- Structure repo : `apps/` (front, backoffice), `services/api`, `packages/` (ui, lib), `docs/`.
- Pratiques : linting auto, tests unitaires sur parcours critiques, revues de code.
- Réutilisation : composants centralisés dans `/components/ui` + storybook interne pour éviter la duplication CSS, variables Tailwind customisées pour la palette.
- Refactor : dette technique suivie dans le backlog, itérations planifiées, pair-programming ponctuel.
- Sécurité continue : checklist OWASP, revues de permissions RBAC, logs d’accès, alerting des anomalies.
- Audits réguliers : audits de code mensuels (qualité, sécurité), revues de dépendances (npm audit, DependaBot), tests de montée en charge trimestriels.
- **Gates CLEAR** : à chaque étape charnière (auth, API, frontend principal, commandes), exécuter revue sécurité + QA (tests autos, revue code croisée, vérif accessibilité, audit de logs) avant passage à l’étape suivante.
- Gestion roadmap : user stories/tâches, Definition of Done incluant tests + docs.
- Support pilote : canal feedback hôtel + voyageurs.

## 9. Prochaines Étapes
1. Détail du schéma de données Supabase pour les features 1 & 2 (tables, colonnes, multi-tenant, triggers realtime).
2. Définition de l'architecture API Node.js (modules, endpoints, auth, RBAC).
3. Conception des interfaces Next.js/Tailwind à partir du design system (layout voyageur/staff) et mise en place d’un kit de composants réutilisables.
4. Préparation pipeline CI/CD sur Render (environnements staging/prod, tests CLEAR, alertes sécurité) et intégration avec Supabase.

Merci de confirmer si tu veux qu’on planifie ensemble les audits (rythme, responsables) avant de passer au schéma Supabase.
