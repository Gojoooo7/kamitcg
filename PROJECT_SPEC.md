# PROJECT_SPEC.md — KamiTCG

Spécification complète du produit. Référence stable, mise à jour uniquement quand une décision produit change.

---

## 1. Vision et concept

KamiTCG est une application mobile de **suivi de portfolio (Portfolio Tracker)** exclusivement dédiée au jeu de cartes à collectionner **One Piece (OPCG)**.

Contrairement aux applications classiques de fans, KamiTCG adopte les **codes visuels et ergonomiques d'une application Fintech** (bourse, crypto). L'objectif est de fournir aux collectionneurs et investisseurs un outil premium pour suivre la valeur financière de leurs cartes avec la précision d'un véritable actif.

**Positionnement** : « Le Trading 212 / Coinbase des cartes One Piece ».

**Cible** :
- Collectionneurs sérieux qui suivent déjà la cote de leurs cartes (Cardmarket, etc.).
- Investisseurs / spéculateurs sur les cartes rares.
- Joueurs compétitifs qui veulent valoriser leur stock.

---

## 2. Fonctionnalités principales

### 2.1 Scanner haute vitesse (OCR)

- Utilisation de l'appareil photo pour lire le **code d'identification unique** de la carte (ex: `OP01-120`, `ST01-007`, `EB01-001`).
- OCR **en local** via Google ML Kit Text Recognition — pas d'appel serveur d'IA d'image, pas de coût récurrent.
- Workflow : ouvrir scanner → cadrer → vibration haptique → carte ajoutée à la collection.
- Fallback manuel : recherche par nom/code si l'OCR échoue.

### 2.2 Tableau de bord financier

- **Valeur totale** de la collection (en €, $ ou monnaie locale).
- **Évolution du portefeuille** sur 24 h, 7 j, 30 j (en valeur absolue et %).
- **Répartition des actifs** : par rareté (Common, Uncommon, Rare, Super Rare, Secret Rare, Leader, Don!!), par extension (OP01, OP02, …, ST01, …, EB01, …), par couleur (Red, Green, Blue, Purple, Black, Yellow).
- **Top movers** : cartes en plus forte hausse / baisse.

### 2.3 Graphiques de marché

- Historique interactif (line/candle chart) montrant l'évolution de la cote d'une carte spécifique sur le marché secondaire.
- Source de données : **Cardmarket** — décision arrêtée (proximité Europe, devise EUR native, couverture OPCG).
- Périodes : 1J, 1S, 1M, 3M, 1A, ALL.

### 2.4 Gestion fine de la collection

- Ajout de cartes avec précision des **spécificités** :
  - Versions alternatives (Alt Art, Manga Art, Parallel).
  - Cartes brillantes (**Foil**) vs non-foil.
  - État (Mint, Near Mint, Light Played, etc.) — optionnel V1.
- **Saisie du prix d'achat initial** pour calculer la plus-value exacte (P&L réalisé / non réalisé).
- Quantité possédée par variation.

---

## 3. Direction artistique (UI / UX)

### 3.1 Ambiance visuelle

- **Dark Mode natif et profond** (fonds quasi noirs, type `#0A0A0F` à `#12121A`).
- Met en valeur l'illustration colorée des cartes réelles.
- Donne un aspect professionnel digne d'une app de courtage.

### 3.2 Palette de couleurs

- **Accent premium** : **doré** (`#D4AF37`) — décision arrêtée.
- **Codes financiers stricts** :
  - Vert (`#22C55E` famille) pour les hausses de valeur.
  - Rouge (`#EF4444` famille) pour les baisses.
- Typographie : sans-serif moderne, chiffres en variante **tabular** pour l'alignement des prix.

### 3.3 Animations et ressenti

- **Retours haptiques** (vibrations) lors des scans réussis.
- Effets visuels **subtils** (parallax, shine) lors de l'ajout d'une carte extrêmement rare.
- Transitions fluides entre dashboard ↔ détail carte ↔ scanner.

---

## 4. Stack technique et outils

| Composant | Technologie | Rôle |
|---|---|---|
| Frontend | **Flutter** | Interface iOS + Android, codebase unique |
| Backend / Auth / DB | **Supabase** | Profils utilisateurs, PostgreSQL, RLS |
| State management | **Riverpod** | Logique interne, état applicatif |
| Scanner | **Google ML Kit — Text Recognition** | OCR local, rapide, sans coût serveur |
| Paiements | **RevenueCat** | Abonnements App Store + Google Play |
| Environnement IDE | Antigravity IDE + Claude Code | Développement assisté par IA |

### 4.1 Authentification

- **V1** : magic link par email uniquement (Supabase Auth `signInWithOtp`).
- **V2+** : ajout de OAuth Google **et** Sign in with Apple en même temps (App Store guideline 4.8 impose Apple dès qu'un autre login social est proposé sur iOS).
- Pas d'OAuth Apple/Google en V1 → pas de risque de rejet App Store, surface de bugs réduite au lancement.

### 4.2 Schéma de données (esquisse Supabase)

- `profiles` (id, email, created_at, premium_until)
- `cards` (id, set_code, card_number, name, rarity, color, image_url) — catalogue maître
- `card_variants` (id, card_id, is_foil, is_alt_art, variant_label)
- `user_collection` (id, user_id, variant_id, quantity, purchase_price, purchased_at, condition)
- `price_history` (id, variant_id, price, currency, source, recorded_at)
- `price_alerts` (id, user_id, variant_id, threshold, direction)

### 4.3 Permissions natives requises

- iOS / Android : **Caméra** (scanner OCR).
- Notifications push (alertes de prix Premium).

---

## 5. Modèle économique

### 5.1 Cible financière

**2 000 € / mois nets** sur l'abonnement.

### 5.2 Freemium

| Tier | Prix | Limites |
|---|---|---|
| **Gratuit** | 0 € | **50 cartes max** dans le portfolio |
| **Premium** | ~4,99 € / mois | Scan illimité, alertes prix temps réel, graphiques détaillés, sync multi-appareils, stats avancées de plus-value |

### 5.3 Calcul d'objectif

- Commission stores : 15 à 30 %.
- Net par abonné : ~3,50 € à ~4,25 € / mois.
- **Cible : 450 à 475 abonnés actifs** pour atteindre 2 000 €/mois nets.

### 5.4 Stratégie d'acquisition (à creuser hors V1)

- Communautés Discord OPCG, Reddit r/OnePieceTCG, créateurs YouTube/Twitch spécialisés.
- ASO (App Store Optimization) sur mots-clés « one piece tcg », « opcg tracker ».

---

## 6. Roadmap haut niveau

- **V0 (MVP technique)** : scaffold + auth Supabase + thème dark + navigation.
- **V1 (MVP utilisable)** : scanner OCR + ajout manuel + dashboard valeur totale + paywall RevenueCat.
- **V2** : graphiques de marché + alertes prix + stats avancées.
- **V3** : sync multi-appareils, social/partage, watchlist publique.

Détail des tâches : voir `TODO.md`.

---

## 7. Hors-scope explicite (V1)

- Pas de marketplace / achat-vente in-app.
- Pas de scan d'image (reconnaissance visuelle de la carte) — seulement le code texte.
- Pas d'autres TCG (Pokémon, Magic, Yu-Gi-Oh!) — focus 100 % One Piece.
- Pas de version web au lancement.
