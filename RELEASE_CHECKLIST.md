# RELEASE_CHECKLIST.md — KamiTCG

Checklist à parcourir intégralement **avant chaque soumission** sur l'App Store et le Google Play Store. Cocher au fur et à mesure dans une copie locale (ou créer une issue par release et y coller la liste). Le détail des règles de fond se trouve dans le bloc Sécurité de `CLAUDE.md` — ce fichier-ci est la version actionnable.

> Convention : `[ ]` à faire · `[x]` validé. Une case non cochée bloque la soumission.

---

## 1. Code & qualité

- [ ] Branche release à jour avec `main`, aucun conflit, aucun fichier non commité.
- [ ] `flutter analyze` → 0 erreur, 0 warning bloquant.
- [ ] `flutter test` → tous les tests verts.
- [ ] Tests d'intégration critiques exécutés au moins une fois sur device réel (scan OCR, paywall, magic link).
- [ ] Aucun `TODO` / `FIXME` critique laissé dans le code de la release (chercher `grep -r "TODO\|FIXME" lib/`).
- [ ] Aucun `print()` ou `debugPrint()` en dehors d'un garde `if (kDebugMode)`.
- [ ] Pas de code mort / fichiers orphelins (`dart analyze --fatal-infos`).

## 2. Dépendances

- [ ] `flutter pub outdated` → aucune dépendance avec CVE connue non patchée.
- [ ] `pubspec.lock` versionné et à jour.
- [ ] Aucune dépendance `git:` ou `path:` non justifiée (toutes en version pub.dev pinnée).
- [ ] Versions des SDK natifs vérifiées : Flutter stable, Android compileSdk à jour, iOS deployment target supporté.

## 3. Secrets & configuration

- [ ] `.env` **absent** du commit (vérifier `git status` + `git log -- .env`).
- [ ] `.env.example` à jour avec toutes les variables requises (sans valeurs).
- [ ] `git secrets --scan` ou `trufflehog filesystem .` → 0 leak.
- [ ] Service_role Supabase **n'apparaît jamais** dans `lib/` (`grep -rn "service_role" lib/` → vide).
- [ ] Clés RevenueCat / Cardmarket / Supabase de **production** utilisées (pas les clés dev/staging).
- [ ] Android keystore et iOS provisioning profile signés avec les certificats de prod.

## 4. Sécurité applicative

- [ ] Tokens stockés via `flutter_secure_storage` uniquement (`grep -rn "SharedPreferences" lib/` → aucune occurrence sur des tokens / sessions).
- [ ] Magic link redirect URLs whitelistées dans le dashboard Supabase (deep link `kamitcg://...` + URL fallback).
- [ ] **Email OTP Expiration ≤ 600 s** (Dashboard → Auth → Providers → Email). Refuser le défaut 3600 s.
- [ ] Sign-out purge complète : secure storage vidé, cache local effacé, providers Riverpod réinitialisés.
- [ ] HTTPS strict : `usesCleartextTraffic="false"` (Android) + ATS strict (iOS Info.plist sans exception).
- [ ] Certificate pinning actif sur les endpoints sensibles en build release.
- [ ] Clé Cardmarket utilisée **uniquement** depuis Edge Function (jamais dans le bundle Flutter).
- [ ] Webhook RevenueCat → Edge Function : signature HMAC vérifiée.

## 5. Base de données Supabase

- [ ] **RLS activée sur 100 % des tables** (vérifier dans le dashboard : `Authentication → Policies`).
- [ ] Politique `deny all` par défaut + ouvertures explicites uniquement.
- [ ] `user_collection`, `price_alerts` : `auth.uid() = user_id` testé manuellement avec deux comptes (impossible de lire les données de l'autre).
- [ ] `profiles.premium_until` : tentative d'écriture côté client → **rejetée**.
- [ ] Tables catalogue (`cards`, `card_variants`) : INSERT/UPDATE/DELETE bloqués au client.
- [ ] CHECK constraints actives sur `purchase_price >= 0`, `quantity > 0`, bornes hautes raisonnables.
- [ ] Index uniques sur `(user_id, variant_id)` (anti-doublons).
- [ ] Migrations à jour, `supabase db diff` propre.
- [ ] Backup automatique Supabase activé.

## 6. Validation des entrées

- [ ] Toutes les entrées utilisateur validées côté client (couche `domain/`) **et** côté serveur (CHECK PG).
- [ ] Codes carte OCR matchés contre regex stricte avant lookup.
- [ ] Recherche manuelle : input échappé, longueur max bornée.
- [ ] Prix d'achat : numeric(12,2), borne haute (ex: 1 000 000).

## 7. Build & obfuscation

- [ ] Build Android : `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info-android/`.
- [ ] Build iOS : `flutter build ipa --release --obfuscate --split-debug-info=build/debug-info-ios/`.
- [ ] Symbols (`debug-info/`) archivés hors repo (Drive privé / S3 chiffré) pour debug crashs futurs.
- [ ] Android : `minifyEnabled true` + `shrinkResources true` en release.
- [ ] iOS : strip symbols actif, Bitcode désactivé.
- [ ] Taille du bundle vérifiée (Android `.aab` < ~50 Mo idéalement).
- [ ] Test du build release sur **device physique** Android + iOS (pas seulement simulateur).

## 8. Permissions natives

- [ ] Android `AndroidManifest.xml` : seules `CAMERA` et `INTERNET` (+ `POST_NOTIFICATIONS` si alertes prix).
- [ ] iOS `Info.plist` : `NSCameraUsageDescription` rédigée en français, claire, justifiée. Idem `NSUserNotificationsUsageDescription`.
- [ ] Demande de permission **just-in-time** (caméra au premier scan, notifs à la première alerte) — pas au lancement.
- [ ] Refus de permission géré gracieusement (fallback recherche manuelle, message non-bloquant).

## 9. Monétisation (RevenueCat)

- [ ] Entitlement `premium` correctement mappé sur les products App Store + Play Store.
- [ ] Sandbox testing iOS : achat → unlock Premium → restore → cancel → downgrade → tout fonctionne.
- [ ] License testing Android : idem (License Tester dans Play Console).
- [ ] **Restore purchases** présent et fonctionnel sur le paywall.
- [ ] Webhook RevenueCat → Supabase Edge Function testé en sandbox.
- [ ] Garde fonctionnelle 50 cartes en gratuit testée (51ᵉ ajout → paywall).

## 10. Privacy & conformité légale

- [ ] **Politique de confidentialité** publiée à une URL stable (ex: GitHub Pages), conforme RGPD.
- [ ] **CGU** publiées à une URL stable.
- [ ] App Store Connect : section Privacy renseignée (data types collected = Email, Purchases, User ID).
- [ ] Play Console : Data Safety form rempli et cohérent avec la politique.
- [ ] Bouton "Supprimer mon compte" présent dans l'app (obligatoire App Store guideline 5.1.1(v) + Play Store).
- [ ] Suppression de compte → CASCADE sur toutes les tables user (`user_collection`, `price_alerts`, etc.).
- [ ] Aucun tracking analytics tiers non consenti (pas de Firebase Analytics, Facebook SDK, etc.).

## 11. Stores — métadonnées

### App Store Connect

- [ ] Nom, sous-titre, mots-clés ASO renseignés (FR + EN minimum).
- [ ] Description rédigée (FR + EN), sans promesse trompeuse, sans mention de prix dans le texte.
- [ ] Screenshots : 6.7", 6.5", 5.5" iPhone — 5 à 6 minimum, sur fond noir cohérent avec la DA.
- [ ] Icône 1024×1024 sans transparence, doré sur fond noir.
- [ ] Catégorie principale : **Finance** (ou **Lifestyle** selon arbitrage ASO).
- [ ] Classement par âge : 4+ (sauf si contenu spécifique).
- [ ] Test informations contact (email + démo si demandé) renseignées pour la review.
- [ ] Build TestFlight validé par au moins 1 testeur externe avant submit.

### Google Play Console

- [ ] Fiche store FR + EN.
- [ ] Screenshots phone (au moins 4) + tablet si supporté.
- [ ] Icône 512×512.
- [ ] Feature graphic 1024×500.
- [ ] Catégorie : **Finance**.
- [ ] Classification PEGI / IARC complétée.
- [ ] Test interne (closed testing) validé avant production.

## 12. Versioning & changelog

- [ ] `pubspec.yaml` `version:` incrémenté (sémantique : `MAJOR.MINOR.PATCH+BUILD`).
- [ ] Build number strictement supérieur à la dernière version publiée sur **chaque** store.
- [ ] Notes de version (changelog) rédigées pour chaque store, en français, < 500 caractères.
- [ ] Tag git créé : `git tag -a v1.x.y -m "..."` + push.

## 13. Post-release (J+0 à J+7)

- [ ] Crashlytics / Sentry (si configuré) : aucun crash bloquant dans la première heure.
- [ ] Vérification Supabase : pas de spike d'erreurs RLS (signe d'un client mal configuré).
- [ ] Test d'achat réel (1 €) sur les deux stores → unlock Premium effectif.
- [ ] Surveillance reviews J+1 / J+3 / J+7, réponse aux retours bloquants.
- [ ] Surveillance latence Edge Functions (sync prix Cardmarket).
- [ ] Communication réseaux / Discord OPCG (si stratégie d'acquisition activée).

---

## Notes

- En cas d'**échec de review App Store / Play Store** : ne pas re-soumettre sans avoir corrigé **et documenté** le motif. Mettre à jour cette checklist si le motif révèle un trou.
- Ce fichier est le **garde-fou final**. Toute exception doit être discutée et tracée (commentaire dans la PR de release).
