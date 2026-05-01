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

  // Scanner ──────────────────────────────────────────────────────────
  static const String scannerTitle = 'Scanner une carte';
  static const String scannerAiming = 'Place la carte dans le cadre';
  static const String scannerDetecting = 'Identification…';
  static const String scannerMatchFound = 'Carte trouvée';
  static const String scannerSkip = 'Ignorer';
  static const String scannerAdd = 'Ajouter au portefeuille';

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
  static const String profileTitle = 'Profil';
  static const String profileSubtitle =
      'Listes de suivi, alertes et compte';
}
