/// Copies utilisateur de l'app — V1 française uniquement.
///
/// L'app est mono-langue pour le moment. Quand l'EN sera ajouté, migrer cette
/// classe vers `flutter_localizations` + fichiers `.arb`. Ne pas écrire de
/// chaînes utilisateur en dur ailleurs — tout passe par `Strings.X`.
class Strings {
  const Strings._();

  // Greeting / Dashboard ─────────────────────────────────────────────
  static const String welcomeBack = 'Bon retour,';
  static const String userDisplayName = 'Nakama';
  static const String portfolioValueLabel = 'VALEUR DU PORTEFEUILLE';
  static const String last24h = 'sur 24 h';

  // Range tabs (1 jour, 1 semaine, 1 mois, 1 an, tout)
  static const List<String> rangeTabs = ['1J', '1S', '1M', '1A', 'TOUT'];

  // Hover tooltip date label, par range
  static String hoverLabelFor(String range) => switch (range) {
        '1J' => '14:00',
        '1S' => 'mer.',
        '1M' => '14 avr.',
        _ => '25 août',
      };

  // Stats row
  static const String statCards = 'Cartes';
  static String statCardsHintWithCount(int sets) =>
      sets <= 1 ? '$sets extension' : '$sets extensions';
  static const String statSecretRare = 'Secret Rare';
  static const String statSecretRareHint = 'rareté max';
  static const String statAllTime = 'Variation';
  static const String statAllTimeHint = 'sur 24 h';

  // Dashboard empty / loading states
  static const String dashboardEmptyTitle = 'Ta collection commence ici';
  static const String dashboardEmptyHint =
      'Ajoute ta première carte pour suivre sa valeur en temps réel.';
  static const String dashboardEmptyCta = 'Ajouter une carte';
  static const String dashboardChartEmpty =
      'Pas encore d’historique sur cette période.';

  // Top performers
  static const String topPerformersTitle = 'Top performers · 24 h';
  static const String seeAll = 'Tout voir';

  // Market pulse
  static const String marketPulseTitle = 'Pouls du marché';
  static const String marketPulseMythicIndex = 'Indice mythique';
  static const String marketPulseAuroraSet = 'Extension Aurora';
  static const String marketPulseEmbergate = 'Embergate';

  // Collection ───────────────────────────────────────────────────────
  static const String collectionTitle = 'Collection';
  static const String collectionSearchPlaceholder = 'Rechercher par nom ou code';
  static const String collectionEmpty = 'Aucune carte ne correspond à ta recherche.';
  static const String sortLabel = 'TRIER';
  static const String sortValue = 'Valeur';
  static const String sort24h = '24 h';
  static const String sortName = 'Nom';
  static const String sortRarity = 'Rareté';
  static String collectionCount(int n) => n == 1 ? '1 carte' : '$n cartes';
  static String collectionSelected(int n) =>
      n == 1 ? '1 sélectionnée' : '$n sélectionnées';
  static const String collectionDeleteTitle = 'Supprimer ?';
  static String collectionDeleteMessage(int n) => n == 1
      ? 'Cette carte sera retirée de ta collection.'
      : 'Ces $n cartes seront retirées de ta collection.';
  static const String collectionDeleteConfirm = 'Supprimer';
  static const String collectionDeleteCancel = 'Annuler';
  static String collectionDeletedSnack(int n) =>
      n == 1 ? '1 carte supprimée' : '$n cartes supprimées';
  static const String collectionDeleteError =
      'Suppression impossible. Réessaie dans un instant.';
  static const String foilTag = 'FOIL';

  // Filter "all" sentinel — partagé entre extensions et raretés
  static const String filterAll = 'Tout';

  // Card detail ──────────────────────────────────────────────────────
  static String detailSetSuffix(String set) => 'Extension $set';
  static String floorCeiling(String floorFmt, String ceilingFmt) =>
      'Plancher €$floorFmt · Plafond €$ceilingFmt';
  static const String priceHistoryTitle = 'HISTORIQUE PRIX · 30 J';
  static String detailHigh(String highFmt) => 'Max €$highFmt';
  static const String detailQuantity = 'Quantité';
  static const String detailHolding = 'Détention';
  static const String detailCostBasis = 'Prix de revient';
  static const String detailUnrealized = 'Plus-value latente';
  static const String detailListForSale = 'Mettre en vente';
  static const String detailTrackPrice = 'Suivre le prix';

  // Édition de position dans la fiche carte
  static const String detailEditTitle = 'MODIFIER MA POSITION';
  static const String detailEditQuantity = 'Quantité';
  static const String detailEditPurchasePrice = 'Prix d’achat unitaire';
  static const String detailEditPurchasePriceHint = 'Optionnel · pour le P&L';
  static const String detailEditSavePrice = 'Enregistrer';
  static const String detailEditDelete = 'Retirer cette carte';
  static const String detailEditDeleteTitle = 'Retirer cette carte ?';
  static const String detailEditDeleteMessage =
      'Cette ligne sera retirée de ta collection.';
  static const String detailEditPriceSaved = 'Prix d’achat mis à jour.';
  static const String detailEditQuantitySaved = 'Quantité mise à jour.';
  static const String detailEditDeleted = 'Carte retirée.';
  static const String detailEditError = 'Mise à jour impossible.';
  static const String detailEditPriceInvalid = 'Prix invalide.';

  // Alertes de prix
  static const String alertsSectionTitle = 'ALERTES DE PRIX';
  static const String alertsEmpty = 'Aucune alerte active.';
  static const String alertsAdd = 'Ajouter une alerte';
  static const String alertsSheetTitle = 'Suivre le prix';
  static String alertsSheetCurrent(String price) => 'Prix actuel : $price';
  static const String alertsActiveLabel = 'Mes alertes actives';
  static const String alertsNewLabel = 'Nouvelle alerte';
  static const String alertsDirectionAbove = 'Au-dessus de';
  static const String alertsDirectionBelow = 'En-dessous de';
  static const String alertsThresholdLabel = 'Seuil';
  static const String alertsCreate = 'Créer l’alerte';
  static const String alertsCreated = 'Alerte créée.';
  static const String alertsDeleted = 'Alerte supprimée.';
  static const String alertsThresholdInvalid = 'Seuil invalide.';
  static const String alertsError = 'Action impossible. Réessaie.';
  static const String alertsNotifsDisclaimer =
      'Les notifications push arrivent en V2. Tes alertes sont enregistrées.';

  // Scanner ──────────────────────────────────────────────────────────
  static const String scannerTitle = 'Scanner une carte';
  static const String scannerAiming = 'Place le code de la carte dans le cadre';
  static const String scannerDetecting = 'Identification…';
  static const String scannerMatchFound = 'Carte trouvée';
  static const String scannerSkip = 'Ignorer';
  static const String scannerAdd = 'Ajouter au portefeuille';
  static const String scannerCameraDenied =
      'Autorisation caméra refusée. Active-la dans les réglages pour scanner.';
  static const String scannerCameraInit =
      'Initialisation de la caméra…';
  static const String scannerNotInCatalogue =
      'Carte non répertoriée dans le catalogue.';
  static const String scannerManualEntry = 'Saisir manuellement';
  static const String scannerVariantPickerTitle = 'Choisis ton illustration';
  static const String scannerZoomHint = 'Pince pour zoomer';

  // Bottom nav ───────────────────────────────────────────────────────
  static const String navHome = 'Accueil';
  static const String navCollection = 'Collection';
  static const String navMarket = 'Marché';
  static const String navProfile = 'Profil';

  // Add card ─────────────────────────────────────────────────────────
  static const String addCardTitle = 'Ajouter une carte';
  static const String addCardSearchPlaceholder = 'Nom ou code (ex : OP01-120)';
  static const String addCardEmpty = 'Aucune carte ne correspond.';
  static const String addCardAdded = 'Ajouté à ta collection';
  static const String addCardAddError =
      'Impossible d’ajouter la carte. Réessaie dans un instant.';

  // Profile ──────────────────────────────────────────────────────────
  static const String profileSignOut = 'Se déconnecter';
  static String profileSignedInAs(String email) => 'Connecté en tant que $email';
  static String profileMemberSince(String date) => 'Membre depuis le $date';
  static const String profileMemberSinceUnknown = 'Membre récent';

  // Premium card
  static const String premiumSectionTitle = 'PLAN';
  static const String premiumFreeLabel = 'Plan gratuit';
  static const String premiumActiveLabel = 'Premium actif';
  static String premiumProgress(int current, int max) =>
      '$current / $max cartes';
  static const String premiumPerksHeader = 'Avec Premium :';
  static const String premiumPerk1 = 'Cartes illimitées dans le portefeuille';
  static const String premiumPerk2 = 'Alertes de prix en temps réel';
  static const String premiumPerk3 = 'Sync multi-appareils';
  static const String premiumPerk4 = 'Statistiques de plus-value avancées';
  static const String premiumCta = 'Passer en Premium · 4,99 €/mois';
  static const String premiumComingSoon = 'Bientôt disponible';
  static const String premiumManage = 'Gérer mon abonnement';
  static String premiumExpires(String date) => 'Renouvellement le $date';

  // Stats section
  static const String profileStatsTitle = 'MES STATISTIQUES';
  static const String profileStatCards = 'Cartes';
  static const String profileStatValue = 'Valeur';
  static const String profileStatSets = 'Extensions';
  static const String profileStatPnl = 'Plus-value';
  static const String profileStatPnlNoBasis = '—';

  // Préférences
  static const String profilePrefsTitle = 'PRÉFÉRENCES';
  static const String profilePrefCurrency = 'Devise';
  static const String profilePrefCurrencySoon = 'Modifiable bientôt';
  static const String profilePrefNotifications = 'Notifications';
  static const String profilePrefNotificationsHint = 'Alertes de prix Premium';
  static const String profilePrefHaptics = 'Retours haptiques';
  static const String profilePrefHapticsHint =
      'Vibrations sur scan, ajout, etc.';

  // Données
  static const String profileDataTitle = 'DONNÉES';
  static const String profileExport = 'Exporter ma collection';
  static const String profileExportHint = 'Copier au format CSV';
  static const String profileExportEmpty = 'Aucune carte à exporter.';
  static const String profileExportSuccess =
      'CSV copié dans le presse-papiers.';
  static const String profileClearCollection = 'Vider ma collection';
  static const String profileClearCollectionHint = 'Toutes les cartes seront retirées';
  static const String profileClearTitle = 'Vider la collection ?';
  static String profileClearMessage(int n) => n == 1
      ? 'Cette carte sera retirée définitivement.'
      : 'Tes $n cartes seront retirées définitivement.';
  static const String profileClearConfirm = 'Tout supprimer';
  static const String profileClearedSuccess = 'Collection vidée.';

  // Compte / Support
  static const String profileAccountTitle = 'COMPTE & SUPPORT';
  static const String profilePrivacy = 'Politique de confidentialité';
  static const String profileTerms = 'Conditions d’utilisation';
  static const String profileVersion = 'Version';
  static const String profileDelete = 'Supprimer mon compte';
  static const String profileDeleteHint = 'Action définitive';
  static const String profileDeleteTitle = 'Supprimer mon compte ?';
  static const String profileDeleteMessage =
      'Cette action est irréversible. Toutes tes cartes, alertes et données seront définitivement effacées.';
  static const String profileDeleteConfirm = 'Tout supprimer';
  static const String profileDeleteError =
      'Suppression impossible. Réessaie dans un instant.';
  static const String profileLinkOpenError =
      'Impossible d’ouvrir le lien. Vérifie ton navigateur.';

  // Auth ─────────────────────────────────────────────────────────────
  static const String authTitle = 'KamiTCG';
  static const String authTagline =
      'Suis la valeur de ta collection comme un actif financier.';
  static const String authEmailLabel = 'Adresse email';
  static const String authEmailPlaceholder = 'toi@exemple.com';
  static const String authEmailInvalid = 'Adresse email invalide';
  static const String authSendMagicLink = 'Recevoir le lien magique';
  static const String authSendingMagicLink = 'Envoi en cours…';
  static String authMagicLinkSent(String email) =>
      'Lien envoyé à $email — vérifie ta boîte mail.';
  static const String authMagicLinkResend = 'Renvoyer';
  static const String authMagicLinkHint =
      'Pas de mot de passe : nous t’envoyons un lien à usage unique pour te connecter en toute sécurité.';
  static const String authError =
      'Impossible d’envoyer le lien. Réessaie dans un instant.';
  static const String authSignOut = 'Se déconnecter';

  // Placeholders ─────────────────────────────────────────────────────
  static const String marketTitle = 'Marché';
  static const String marketSubtitle =
      'Extensions tendance, indice mythique et prix planchers en direct';
  static const String marketTopGainers = 'TOP GAGNANTS · 24 H';
  static const String marketTopLosers = 'TOP PERDANTS · 24 H';
  static const String marketIndices = 'INDICES PAR EXTENSION';
  static const String marketTopExpensive = 'CARTES LES PLUS CHÈRES';
  static const String marketEmpty = 'Pas encore de données.';
  static const String marketSyntheticDisclaimer =
      'Prix synthétiques · sera remplacé par Cardmarket prochainement.';
  static const String profileTitle = 'Profil';
  static const String profileSubtitle =
      'Listes de suivi, alertes et compte';
}
