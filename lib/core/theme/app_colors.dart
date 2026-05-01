import 'package:flutter/material.dart';

/// Tokens de couleur extraits 1:1 du design Claude Design (KamiTCG.html).
/// Toute couleur visible dans l'app doit provenir de cette classe.
class AppColors {
  const AppColors._();

  // Backgrounds
  static const Color bg0 = Color(0xFF0A0A0B);
  static const Color bg1 = Color(0xFF111113);
  static const Color bg2 = Color(0xFF17171A);
  static const Color bg3 = Color(0xFF1F1F23);
  static const Color bgRoot = Color(0xFF050507);

  // Lignes / bordures
  static const Color line = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color line2 = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)

  // Texte
  static const Color text0 = Color(0xFFF5F5F7);
  static const Color text1 = Color(0xFFB4B4BA);
  static const Color text2 = Color(0xFF6E6E76);
  static const Color text3 = Color(0xFF45454B);

  // Accent premium
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFFB8932E);
  static const Color goldLight = Color(0xFFE8C455);
  static const Color goldSoft = Color(0x24D4AF37); // rgba(212,175,55,0.14)

  // Accent secondaire
  static const Color violet = Color(0xFF8A2BE2);
  static const Color violet2 = Color(0xFFA855F7);
  static const Color violetSoft = Color(0x2E8A2BE2); // rgba(138,43,226,0.18)

  // Codes financiers
  static const Color up = Color(0xFF00E676);
  static const Color upSoft = Color(0x1F00E676); // rgba(0,230,118,0.12)
  static const Color down = Color(0xFFFF3B5C);
  static const Color downSoft = Color(0x1FFF3B5C); // rgba(255,59,92,0.12)

  // Couleurs de rareté OPCG (mapping ring/text par rareté pour les pills + bordures de carte).
  static const Color raritySecretRareRing = Color(0xFFD4AF37);
  static const Color raritySecretRareText = Color(0xFFF5D67E);
  static const Color raritySpecialAltRing = Color(0xFFFF4DA6);
  static const Color raritySpecialAltText = Color(0xFFFFA8D0);
  static const Color rarityTreasureRareRing = Color(0xFFFF7847);
  static const Color rarityTreasureRareText = Color(0xFFFFB89A);
  static const Color raritySuperRareRing = Color(0xFFA855F7);
  static const Color raritySuperRareText = Color(0xFFD7A6FF);
  static const Color rarityLeaderRing = Color(0xFFFF8B3D);
  static const Color rarityLeaderText = Color(0xFFFFC196);
  static const Color rarityRareRing = Color(0xFF5DC2FF);
  static const Color rarityRareText = Color(0xFFA8DCFF);
  static const Color rarityUncommonRing = Color(0xFF5DC282);
  static const Color rarityUncommonText = Color(0xFFA8DCB4);
  static const Color rarityCommonRing = Color(0xFF6E6E76);
  static const Color rarityCommonText = Color(0xFFB4B4BA);
  static const Color rarityDonRing = Color(0xFFFFB347);
  static const Color rarityDonText = Color(0xFFFFD89E);
  static const Color rarityPromoRing = Color(0xFFFF6EC4);
  static const Color rarityPromoText = Color(0xFFFFB0DD);

  // Card art gradients (placeholders) — extraits 1:1 de KamiTCG.html
  static const List<Color> artA = [Color(0xFF2A1A4A), Color(0xFF6E29A8), Color(0xFFC084FC)];
  static const List<Color> artB = [Color(0xFF1F3A1F), Color(0xFF2F8A4A), Color(0xFFC5E87A)];
  static const List<Color> artC = [Color(0xFF3A1A1A), Color(0xFFB34141), Color(0xFFFFB46E)];
  static const List<Color> artD = [Color(0xFF102540), Color(0xFF2563A8), Color(0xFF6DD6FF)];
  static const List<Color> artE = [Color(0xFF2A2A2E), Color(0xFF5A5A64), Color(0xFFD4AF37)];
  static const List<Color> artF = [Color(0xFF2B1A3A), Color(0xFF8A2BE2), Color(0xFFFF6EC4)];
  static const List<Color> artG = [Color(0xFF1A1A1A), Color(0xFF3A3A3A), Color(0xFFD4AF37)];
  static const List<Color> artH = [Color(0xFF3A2A10), Color(0xFFA07020), Color(0xFFF0D27A)];
}
