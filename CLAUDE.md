# CLAUDE.md — KamiTCG

> Ce fichier est lu automatiquement par Claude Code au début de chaque session. Lire aussi `PROJECT_SPEC.md` pour la vision complète et `TODO.md` pour l'état d'avancement.

## Pitch

KamiTCG est un **portfolio tracker mobile pour le jeu de cartes One Piece (OPCG)**, conçu avec les codes UX de la Fintech (bourse / crypto). Cible : collectionneurs/investisseurs qui veulent suivre la valeur financière de leurs cartes comme un actif.

## Stack technique

| Composant | Choix | Notes |
|---|---|---|
| Framework | **Flutter** (Dart SDK ^3.11.5) | iOS + Android, codebase unique |
| State management | **Riverpod** | Pas de Provider/Bloc/GetX |
| Backend / Auth / DB | **Supabase** (PostgreSQL) | Pas de Firebase pour la DB |
| OCR (scanner) | **Google ML Kit — Text Recognition** | Lecture **en local** du code carte (ex: `OP01-120`). Aucun appel serveur d'IA. |
| Paiements / Subs | **RevenueCat** | App Store + Google Play |
| Données marché | **Cardmarket** ou **TCGPlayer** | À arbitrer (CGU, pricing API) |

## Direction artistique (non-négociable)

- **Dark mode natif et profond** (pas de light mode au lancement).
- **Accent premium** : doré (`#D4AF37`).
- **Codes financiers stricts** : vert pour les hausses, rouge pour les baisses. Toujours.
- **Retours haptiques** sur scan réussi ; effets visuels subtils sur cartes très rares.

## Modèle économique

- **Freemium**. Gratuit limité à 50–100 cartes. Premium ~4,99 €/mois.
- Objectif : **2 000 €/mois nets** ⇒ ~450–475 abonnés actifs (après 15–30 % de commission stores).
- **Premium** = scan illimité, alertes prix temps réel, graphiques détaillés, sync multi-appareils, stats de plus-value.

## Règles de travail (à respecter par défaut)

1. **Toujours répondre en français** — l'utilisateur travaille en français.
2. **Toujours consulter `TODO.md`** avant de proposer du travail, et le mettre à jour quand une tâche avance ou se termine.
3. **Ne jamais introduire** Firebase (DB), Provider/Bloc/GetX, ou un service OCR cloud — les choix techniques ci-dessus sont arrêtés.
4. **Ne pas créer de fichiers `.md` de documentation** (notes, recaps, plans intermédiaires) sans demande explicite. Les seuls `.md` du projet sont : `CLAUDE.md`, `PROJECT_SPEC.md`, `TODO.md`, `RELEASE_CHECKLIST.md`, `README.md`.
5. **Préférer éditer** les fichiers existants plutôt que d'en créer de nouveaux.
6. **Architecture lib/** — feature-first (un dossier par feature : `auth/`, `portfolio/`, `scanner/`, `market/`, `paywall/`), avec sous-dossiers `data/`, `domain/`, `presentation/`. À mettre en place dès qu'on dépasse le scaffold initial.
7. **Tests** — au minimum un test unitaire pour chaque service métier (parseur OCR, calcul plus-value, repository Supabase mocké).

## Sécurité (à respecter par défaut)

KamiTCG manipule des données financières (prix d'achat, plus-value, reçus de paiement) et des comptes utilisateurs — la sécurité est un critère **de premier ordre**, pas un nice-to-have. Ces règles s'appliquent à tout code écrit dans ce repo.

### Secrets & configuration

- **Aucun secret en clair dans le repo.** Supabase URL + anon key, RevenueCat public SDK key, Cardmarket credentials → fichier `.env` chargé via `flutter_dotenv`, et `.env` dans `.gitignore`.
- Le **service_role** Supabase ne doit **jamais** apparaître dans le client Flutter. Réservé aux Edge Functions / cron côté serveur.
- Clés signées (Android keystore, iOS provisioning) → hors repo, gérées via CI secrets ou trousseau local.
- Auditer le repo avec `git secrets` ou `trufflehog` avant chaque release.

### Authentification & sessions

- Stockage des tokens Supabase via **`flutter_secure_storage`** (Keychain iOS / Keystore Android). **Jamais** `SharedPreferences` ni un fichier en clair.
- Magic link : whitelister strictement les **redirect URLs** dans le dashboard Supabase (deep link `kamitcg://auth/callback` + URL de fallback web). Refuser tout autre redirect.
- Refresh token rotation activée côté Supabase. Sign-out → purge complète du secure storage.
- Garde de routes côté client **et** RLS côté serveur (jamais l'un sans l'autre).

### Base de données (Supabase / PostgreSQL)

- **RLS activée sur 100 % des tables**, y compris les tables de catalogue. Politique par défaut : **deny all**, puis ouvrir explicitement.
- `user_collection`, `price_alerts` : `auth.uid() = user_id` sur SELECT/INSERT/UPDATE/DELETE.
- `profiles` : un user ne lit/écrit que sa propre ligne. Le champ `premium_until` est **lecture seule** côté client (mis à jour uniquement par le webhook RevenueCat → Edge Function).
- Tables catalogue (`cards`, `card_variants`) : SELECT public, INSERT/UPDATE/DELETE bloqués au client.
- Toutes les requêtes passent par le **client Supabase paramétré** (jamais de SQL concaténé même côté Edge Function).
- Index uniques sur `(user_id, variant_id)` pour empêcher les doublons par injection logique.

### Réseau & APIs externes

- **HTTPS uniquement.** Bloquer le clear-text dans `AndroidManifest.xml` (`android:usesCleartextTraffic="false"`) et `Info.plist` (ATS strict).
- Envisager le **certificate pinning** pour Supabase et Cardmarket sur les builds release (via `dio` + `dio_certificate_pinning` ou équivalent), au moins pour les endpoints qui transitent des tokens / receipts.
- Tout appel Cardmarket → côté **Edge Function** (la clé Cardmarket ne touche jamais le device).
- Validation stricte des webhooks RevenueCat → Supabase (HMAC signature check côté Edge Function).

### Validation des entrées

- Tout input utilisateur (recherche carte, prix d'achat manuel, quantité) → **validation côté client ET côté serveur** (CHECK constraints PostgreSQL + validation dans la couche `domain/`).
- Prix : `numeric(12,2)`, `>= 0`, borne haute raisonnable (ex: 1 000 000) pour bloquer les overflows logiques.
- Quantités : entier `> 0`, borne haute (ex: 9999).
- Codes carte OCR : matcher contre une regex stricte avant lookup catalogue.

### Stockage local

- Si on cache la collection en local (Hive/Isar/SQLite), **chiffrer** avec une clé stockée en `flutter_secure_storage`.
- Aucun cache d'images en clair dans un dossier publiquement accessible (utiliser le dossier app-private).
- Effacer le cache local au sign-out.

### Build & distribution

- **Obfuscation** Dart en release : `flutter build --obfuscate --split-debug-info=build/debug-info/`.
- Android : ProGuard/R8 activés, `minifyEnabled true` en release.
- iOS : Bitcode désactivé (déprécié), strip symbols.
- Désactiver tous les `print()` et logs verbeux en release (utiliser un logger conditionnel sur `kReleaseMode`).
- **Aucun log** ne doit jamais contenir : token, email, mot de passe, receipt RevenueCat, prix d'achat, ID Supabase complet d'un user.

### Dépendances

- `flutter pub outdated` avant chaque release ; mise à jour des dépendances avec CVE connues sans délai.
- Pas de package non maintenu (> 1 an sans commit) sans justification écrite.
- Lockfile (`pubspec.lock`) versionné.

### Permissions natives (principe du moindre privilège)

- Caméra : demande **just-in-time** au premier scan, pas au lancement de l'app.
- Notifications : demande au moment d'activer une alerte de prix, pas avant.
- Aucune permission de stockage externe, contacts, localisation — non justifiées par le produit.

### Vie privée & PII

- Collecter le minimum : email + données de collection. **Pas** de tracking analytics intrusif (pas de Firebase Analytics, pas de Facebook SDK).
- Si un outil produit est ajouté (ex: PostHog/Plausible self-hosted), respecter RGPD : consentement explicite, opt-out simple, pas de PII envoyée.
- Politique de confidentialité + droit à l'effacement (delete account → CASCADE sur toutes les tables user).

### Référentiel

- Toute décision de sécurité non couverte ici → s'aligner sur **OWASP Mobile Top 10** (M1 à M10) et les recommandations Supabase officielles.

## État actuel du projet (snapshot — vérifier `git log` pour l'à-jour)

- Scaffold Flutter par défaut (compteur). `lib/main.dart` est encore le template, **à remplacer**.
- `pubspec.yaml` ne contient encore **aucune** dépendance métier (Riverpod, Supabase, ML Kit, RevenueCat à ajouter).
- Aucun thème, aucune route, aucune feature implémentée.

## Commandes utiles

```bash
flutter pub get              # installer les deps
flutter run                  # lancer en debug
flutter analyze              # lint
flutter test                 # tests
flutter build apk --release  # build Android
flutter build ios --release  # build iOS (macOS uniquement)
```
