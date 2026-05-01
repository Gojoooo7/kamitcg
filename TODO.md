# TODO.md — KamiTCG

État d'avancement et prochaines tâches. À mettre à jour à chaque session de travail.

**Légende** : `[ ]` à faire · `[~]` en cours · `[x]` fait · `[?]` à arbitrer

---

## Phase 0 — Fondations projet

- [x] Initialiser le projet Flutter (scaffold)
- [x] Remplacer le contenu par défaut de `lib/main.dart` (compteur)
- [x] Mettre en place l'arborescence `lib/` feature-first
  - [x] `lib/core/` (theme, router, constants, utils, widgets)
  - [x] `lib/features/auth/`
  - [x] `lib/features/portfolio/`
  - [x] `lib/features/scanner/`
  - [x] `lib/features/market/`
  - [x] `lib/features/paywall/`
  - [x] `lib/features/profile/`
- [x] Ajouter les dépendances dans `pubspec.yaml` (versions latest pub.dev) :
  - [x] `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`
  - [x] `supabase_flutter`
  - [x] `google_mlkit_text_recognition`
  - [x] `camera`
  - [x] `purchases_flutter` (RevenueCat)
  - [x] `go_router` (navigation) — installé, à brancher quand on aura l'auth
  - [x] `fl_chart` (graphiques) — installé, on utilise un CustomPainter pour le moment
  - [x] `flutter_secure_storage` (tokens)
  - [x] `intl` (formatage prix/dates)
  - [x] `freezed` + `json_serializable` (modèles immuables)
  - [x] `flutter_dotenv` + `google_fonts`
  - [ ] Réactiver `riverpod_lint` + `custom_lint` quand l'écosystème lève le pin analyzer ^8
- [x] Configurer `analysis_options.yaml` avec règles strictes
- [ ] Créer un `README.md` projet (build, run, env vars)

## Phase 1 — Design system & thème

- [x] Palette définitive : doré (`#D4AF37`) — décision arrêtée
- [x] Implémenter `AppTheme` dark mode (couleurs, typographie tabular)
- [x] Implémenter le design KamiTCG.html : Dashboard, Collection, CardDetail, Scanner, BottomNav + FAB
- [x] Composants de base : `DeltaBadge`, `Sparkline`, `LineChartView`, `CardArtTile`, `RarityPill`, `StatTile`, `IconButtonChip`, `BottomNavShell`
- [x] Système d'icônes : Material (`Icons.*`) — minimaliste, suffisant pour V1
- [ ] Tester le rendu sur device iOS + Android physique (cf. ci-dessous, pas de device disponible côté Claude)

## Phase 2 — Auth & Backend Supabase

- [x] Créer le projet Supabase + stocker URL/anon key dans `.env` (via `flutter_dotenv`)
- [x] MCP Supabase connecté côté Claude Code (lecture/migrations)
- [x] Schéma SQL initial (migration `initial_schema`) — `profiles`, `cards`, `card_variants`, `user_collection`, `price_history`, `price_alerts`
- [x] Politiques RLS deny-all par défaut + policies explicites par table (CLAUDE.md)
- [x] Triggers : `handle_new_user` (auto-profile à l'inscription), `protect_premium_until`, `touch_updated_at` × 2
- [x] Hardening fonctions (search_path pinné, EXECUTE révoqué sur `handle_new_user`) — `get_advisors security` retourne 0
- [ ] Écran login / signup — **V1 : magic link email uniquement** (Supabase `signInWithOtp`)
- [ ] (V2) Ajouter OAuth Google + Sign in with Apple ensemble (guideline App Store 4.8)
- [ ] Provider Riverpod `authStateProvider`
- [ ] Garde de routes (redirection si non connecté)
- [ ] Brancher le client Supabase Flutter au démarrage (chargement `.env` → `Supabase.initialize`)

## Phase 3 — Scanner OCR

- [ ] Permission caméra (iOS Info.plist + Android manifest)
- [ ] Écran scanner avec preview caméra et zone de cadrage
- [ ] Intégration ML Kit Text Recognition
- [ ] **Parseur de codes carte** (regex `^(OP|ST|EB|P)\d{2}-\d{3}$` + variantes)
- [ ] Vibration haptique sur scan réussi (`HapticFeedback.mediumImpact`)
- [ ] Lookup catalogue : code → carte Supabase
- [ ] Modale de confirmation (variante : foil ? alt art ? quantité ? prix d'achat ?)
- [ ] Fallback : recherche manuelle par nom/code

## Phase 4 — Portfolio & Dashboard

- [x] `CardRepository`, `CollectionRepository`, `PriceRepository` (Supabase)
- [x] Domain models : `CatalogueCard`, `CardVariant`, `CollectionItem`, `DisplayCard`
- [x] Providers Riverpod : `catalogueProvider`, `collectionProvider`, `portfolioStatsProvider`, `portfolioChartProvider`
- [x] Seed minimal du catalogue OPCG (15 cartes, 24 variants, 720 points de prix)
- [x] Écran Dashboard branché sur les providers (+ empty state CTA "Ajouter une carte")
- [x] Écran Collection branché (filtres set/rareté dynamiques + sort + search)
- [x] Écran détail carte (déjà branché via DisplayCard)
- [x] Flow "Ajouter une carte" — browse catalogue + tap = insert dans `user_collection`
- [x] Sign-out depuis le Profil (purge automatique du secure storage)
- [ ] Donut répartition (par rareté / extension / couleur) — V2
- [ ] Calcul plus-value réalisée vs non réalisée — V2

## Phase 5 — Données de marché

- [ ] Lecture CGU + pricing API **Cardmarket** (source arrêtée), créer le compte développeur
- [ ] Job de synchro des prix Cardmarket (Edge Function Supabase ou cron externe)
- [ ] Stockage `price_history` (snapshot quotidien minimum)
- [ ] Graphique interactif `fl_chart` (1J / 1S / 1M / 3M / 1A / ALL)

## Phase 6 — Monétisation (RevenueCat)

- [ ] Créer compte RevenueCat + lier App Store Connect + Play Console
- [ ] Définir entitlement `premium` et offering `default`
- [ ] Intégration `purchases_flutter` au démarrage (identify user)
- [ ] Écran Paywall (USP, prix, restore purchases, mentions légales)
- [ ] Garde fonctionnelle : limite **50 cartes** en gratuit
- [ ] Provider `subscriptionStatusProvider`

## Phase 7 — Premium features

- [ ] Alertes de prix (notifs push via Supabase + FCM/APNs)
- [ ] Stats avancées (P&L total, ROI, meilleure/pire carte, hold time moyen)
- [ ] Sync multi-appareils (déjà natif via Supabase, à valider)
- [ ] Export CSV de la collection

## Phase 8 — Polish & lancement

- [ ] Animations subtiles (Hero transitions, shimmer sur cartes rares)
- [ ] Tests :
  - [ ] Unitaires : parseur OCR, calcul P&L, repository
  - [ ] Widget : composants design system
  - [ ] Intégration : flow scan → ajout → dashboard
- [ ] Icônes app + splash screen (doré/violet sur fond noir)
- [ ] Screenshots stores (5–6 par plateforme)
- [ ] Politique de confidentialité + CGU (hébergées, ex: GitHub Pages)
- [ ] Soumission App Store + Play Store — **dérouler `RELEASE_CHECKLIST.md` intégralement avant chaque soumission**

---

## Décisions arrêtées

- [x] **Couleur d'accent** : doré (`#D4AF37`)
- [x] **Source données marché** : Cardmarket
- [x] **Limite gratuite** : 50 cartes
- [x] **Auth V1** : magic link email uniquement (Google + Apple ensemble en V2)

## Décisions en attente d'arbitrage

- [?] **Devise par défaut** : EUR (Cardmarket-friendly) ou auto selon locale ?
