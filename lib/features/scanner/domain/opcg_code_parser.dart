/// Extrait un code carte OPCG (`OP01-120`, `ST01-007`, `P-001`, …) d'un texte
/// OCR brut. Robuste au bruit (copyright Bandai, traductions, etc.).
///
/// Format Bandai officiel :
///   `<set><numero>` où :
///   - set : 1-3 lettres + 0-3 chiffres (`OP01`, `ST01`, `EB01`, `PRB01`, `P`)
///   - numero : `XXX` ou `XXX_pY` (parallel/alt-art)
class OpcgCodeParser {
  const OpcgCodeParser._();

  /// Pattern strict : limites de mot autour pour éviter les faux positifs au
  /// milieu d'une phrase. `\d{3}` exige 3 chiffres exacts (les codes OPCG sont
  /// toujours 3 chiffres : 001 → 999). Insensible à la casse pour gérer le
  /// suffixe `_p1` qui passe en `_P1` après normalisation.
  static final RegExp _pattern = RegExp(
    r'\b([A-Z]{1,3}\d{0,3})-(\d{3})(_p\d+)?\b',
    caseSensitive: false,
  );

  /// Tous les codes potentiels trouvés, déduplique et préserve l'ordre.
  static List<String> extractAll(String rawText) {
    final normalized = _normalize(rawText);
    final out = <String>[];
    final seen = <String>{};
    for (final match in _pattern.allMatches(normalized)) {
      final code = match.group(0)!;
      if (!_isValidPrefix(match.group(1)!)) continue;
      if (seen.add(code)) out.add(code);
    }
    return out;
  }

  /// Le premier code valide, ou null. Pratique pour le scanner où on veut
  /// juste savoir « est-ce qu'on a quelque chose à matcher ».
  static String? tryExtract(String rawText) {
    final all = extractAll(rawText);
    return all.isEmpty ? null : all.first;
  }

  /// Normalisations communes des erreurs OCR :
  /// - Majuscule globale
  /// - `0` → `O` quand ils précèdent immédiatement un autre lettre/chiffre dans
  ///   un préfixe (mais on garde les vrais zéros). Heuristique : on n'altère
  ///   pas le texte, on accepte les deux (regex tolérante en ne forçant pas).
  static String _normalize(String raw) {
    return raw.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Whitelist des préfixes set OPCG attendus pour réduire les faux positifs.
  /// (Sans ça, du texte aléatoire `XX1-001` matcherait.)
  static bool _isValidPrefix(String prefix) {
    return _knownPrefixes.contains(prefix);
  }

  /// Préfixes connus du catalogue OPCG (mis à jour quand de nouveaux sets
  /// sortent). Liste alignée sur les sets seedés via le script d'import.
  static const Set<String> _knownPrefixes = {
    // Booster packs principaux OP-01 → OP-15 (et au-delà à mettre à jour)
    'OP01', 'OP02', 'OP03', 'OP04', 'OP05', 'OP06', 'OP07', 'OP08',
    'OP09', 'OP10', 'OP11', 'OP12', 'OP13', 'OP14', 'OP15', 'OP16',
    'OP17', 'OP18', 'OP19', 'OP20',
    // Starter Decks
    'ST01', 'ST02', 'ST03', 'ST04', 'ST05', 'ST06', 'ST07', 'ST08',
    'ST09', 'ST10', 'ST11', 'ST12', 'ST13', 'ST14', 'ST15', 'ST16',
    'ST17', 'ST18', 'ST19', 'ST20', 'ST21', 'ST22', 'ST23', 'ST24',
    'ST25', 'ST26', 'ST27', 'ST28', 'ST29', 'ST30',
    // Extra Boosters
    'EB01', 'EB02', 'EB03', 'EB04', 'EB05',
    // Premium Boosters
    'PRB01', 'PRB02', 'PRB03',
    // Promos
    'P',
  };
}
