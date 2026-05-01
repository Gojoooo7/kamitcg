// Import one-shot du catalogue OPCG depuis le site officiel Bandai.
//
// USAGE :
//   1. Renseigner SUPABASE_SERVICE_ROLE_KEY dans .env (Dashboard → Settings → API)
//   2. dart run scripts/import_catalogue.dart
//
// Ce script lit le HTML public de https://en.onepiece-cardgame.com/cardlist/
// (source officielle Bandai) pour chaque series_id, en extrait les cartes et
// upsert dans `public.cards` + `public.card_variants` via PostgREST.
//
// Les images haute résolution sont accessibles à
// https://en.onepiece-cardgame.com/images/cardlist/card/{CODE}.png
// (~600×838 px). Le script stocke uniquement l'URL — le client Flutter cache
// localement via `cached_network_image`.
//
// Le service_role est requis car la table `cards` a RLS deny-all pour les
// clients ; seul service_role bypass RLS. Cette clé ne doit JAMAIS être
// embarquée dans le bundle Flutter — uniquement utilisée localement.

import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

const String _bandaiBaseUrl = 'https://en.onepiece-cardgame.com';

/// Series IDs Bandai → libellé court (extrait du `<select>` du site Bandai
/// le 2026-05-01). À mettre à jour quand de nouvelles extensions sortent.
const Map<String, String> _seriesIds = {
  // Booster packs principaux
  '569101': 'OP-01 Romance Dawn',
  '569102': 'OP-02 Paramount War',
  '569103': 'OP-03 Pillars of Strength',
  '569104': 'OP-04 Kingdoms of Intrigue',
  '569105': 'OP-05 Awakening of the New Era',
  '569106': 'OP-06 Wings of the Captain',
  '569107': 'OP-07 500 Years in the Future',
  '569108': 'OP-08 Two Legends',
  '569109': 'OP-09 Emperors in the New World',
  '569110': 'OP-10 Royal Blood',
  '569111': 'OP-11 A Fist of Divine Speed',
  '569112': 'OP-12 Legacy of the Master',
  '569113': 'OP-13 Carrying On His Will',
  '569114': 'OP-14 The Azure Sea\'s Seven',
  '569115': 'OP-15 Adventure on Kami\'s Island',
  // Extra Booster
  '569201': 'EB-01 Memorial Collection',
  '569202': 'EB-02 Anime 25th Collection',
  '569203': 'EB-03 One Piece Heroines Edition',
  // Premium Booster
  '569301': 'PRB-01',
  '569302': 'PRB-02',
  // Starter Decks
  '569001': 'ST-01 Straw Hat Crew',
  '569002': 'ST-02 Worst Generation',
  '569003': 'ST-03 The Seven Warlords of the Sea',
  '569004': 'ST-04 Animal Kingdom Pirates',
  '569005': 'ST-05 One Piece Film edition',
  '569006': 'ST-06 Absolute Justice',
  '569007': 'ST-07 Big Mom Pirates',
  '569008': 'ST-08 Monkey D. Luffy',
  '569009': 'ST-09 Yamato',
  '569010': 'ST-10 The Three Captains',
  '569011': 'ST-11 Uta',
  '569012': 'ST-12 Zoro and Sanji',
  '569013': 'ST-13 The Three Brothers',
  '569014': 'ST-14 3D2Y',
  '569015': 'ST-15 Red Edward.Newgate',
  '569016': 'ST-16 Green Uta',
  '569017': 'ST-17 Blue Donquixote Doflamingo',
  '569018': 'ST-18 Purple Monkey.D.Luffy',
  '569019': 'ST-19 Black Smoker',
  '569020': 'ST-20 Yellow Charlotte Katakuri',
  '569021': 'ST-21 GEAR5',
  '569022': 'ST-22 Ace & Newgate',
  '569023': 'ST-23 RED Shanks',
  '569024': 'ST-24 GREEN Jewelry Bonney',
  '569025': 'ST-25 BLUE Buggy',
  '569026': 'ST-26 PURPLE/BLACK Monkey.D.Luffy',
  '569027': 'ST-27 BLACK Marshall.D.Teach',
  '569028': 'ST-28 GREEN/YELLOW Yamato',
  '569029': 'ST-29 Egghead',
  // Promos
  '569901': 'Promotion card',
  '569801': 'Other Product Card',
};

/// Une carte parsée depuis le HTML Bandai.
class _ParsedCard {
  _ParsedCard({
    required this.fullCode,
    required this.baseCode,
    required this.setCode,
    required this.cardNumber,
    required this.variantSuffix,
    required this.name,
    required this.rarity,
    required this.cardType,
    required this.colors,
    required this.imageUrl,
  });

  /// Code complet vu sur le site (ex `OP01-001`, `OP01-001_p1`).
  final String fullCode;

  /// Code de la carte de base (ex `OP01-001`).
  final String baseCode;

  final String setCode;
  final String cardNumber;

  /// Suffixe variant (ex `_p1`, `_p2`) ou null pour la carte de base.
  final String? variantSuffix;

  final String name;
  final String rarity;
  final String? cardType;
  final List<String> colors;
  final String imageUrl;

  bool get isAltArt => variantSuffix != null;
}

/// Parse une variable d'environnement depuis `.env` (lecture simple, pas de
/// gestion d'échappement pour rester sans dépendance).
Map<String, String> _readDotEnv(File file) {
  final result = <String, String>{};
  if (!file.existsSync()) return result;
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final eq = trimmed.indexOf('=');
    if (eq <= 0) continue;
    final key = trimmed.substring(0, eq).trim();
    var value = trimmed.substring(eq + 1).trim();
    if (value.startsWith('"') && value.endsWith('"') && value.length >= 2) {
      value = value.substring(1, value.length - 1);
    }
    result[key] = value;
  }
  return result;
}

/// Récupère le HTML d'un set Bandai et extrait toutes les cartes.
Future<List<_ParsedCard>> _fetchSet(
  String seriesId,
  String seriesLabel,
  http.Client client,
) async {
  final url = '$_bandaiBaseUrl/cardlist/?series=$seriesId';
  final response = await client.get(Uri.parse(url), headers: {
    'User-Agent':
        'KamiTCG-Importer/1.0 (one-shot import for personal portfolio app)',
    'Accept-Language': 'en-US,en;q=0.9',
  });
  if (response.statusCode != 200) {
    stderr.writeln('  ⚠ HTTP ${response.statusCode} sur $url — set ignoré');
    return [];
  }

  final document = html_parser.parse(response.body);
  final blocks = document.querySelectorAll('dl.modalCol');
  final cards = <_ParsedCard>[];

  for (final block in blocks) {
    try {
      // Source de vérité du code = id HTML (`OP01-001`, `OP01-001_p1`, etc.).
      // Le <span> visible affiche le même code base pour tous les variants
      // d'une même carte (les alt-arts ne montrent pas le _p1 à l'œil), donc
      // on ne peut pas l'utiliser pour différencier base et alt-art.
      final id = block.attributes['id'];
      if (id == null) continue;
      final fullCode = id.trim();

      final infoSpans = block.querySelectorAll('dt .infoCol span');
      if (infoSpans.length < 3) continue;
      final rarity = _normalizeRarity(infoSpans[1].text.trim());
      final cardType = infoSpans[2].text.trim();
      if (rarity == null) {
        // Rareté inconnue (ex : SR★, R★ — variantes de print qu'on traite
        // comme alt-art mais qu'on n'arrive pas à mapper proprement). On skip
        // pour ne pas violer le CHECK Postgres.
        continue;
      }

      final nameEl = block.querySelector('dt .cardName');
      final name = nameEl?.text.trim() ?? '';

      // URL d'image déterministe à partir du code. Bandai héberge toutes les
      // images selon ce pattern, même quand le HTML public utilise un
      // placeholder (cas EB04-007 base : pas linkée mais l'URL existe).
      final imageUrl =
          '$_bandaiBaseUrl/images/cardlist/card/$fullCode.png';

      final colorEl = block.querySelector('dd .color');
      final colorText = colorEl == null
          ? ''
          : colorEl.text.replaceFirst('Color', '').trim();
      final colors = colorText
          .split('/')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();

      // Décompose le code : OP01-001, ST01-012, P-005, OP01-001_p1, OP01-001_r1…
      // Suffixes connus :
      //   _pN = parallel/alt-art (illustration différente)
      //   _rN = reprint (réimpression dans un set ultérieur, souvent holo)
      final match =
          RegExp(r'^([A-Z]+\d*)-(\d+)((?:_p|_r)\d+)?$', caseSensitive: false)
              .firstMatch(fullCode);
      if (match == null) {
        stderr.writeln('  ⚠ Code non reconnu : "$fullCode"');
        continue;
      }
      final setCode = match.group(1)!;
      final cardNumber = match.group(2)!;
      final variantSuffix = match.group(3);
      final baseCode = '$setCode-$cardNumber';

      cards.add(_ParsedCard(
        fullCode: fullCode,
        baseCode: baseCode,
        setCode: setCode,
        cardNumber: cardNumber,
        variantSuffix: variantSuffix,
        name: name,
        rarity: rarity,
        cardType: _normalizeCardType(cardType),
        colors: colors,
        imageUrl: imageUrl,
      ));
    } catch (e) {
      stderr.writeln('  ⚠ Bloc ignoré ($seriesLabel) : $e');
    }
  }

  return cards;
}

/// Normalise la rareté affichée par Bandai vers nos codes Postgres.
/// Retourne `null` si la rareté est inconnue (la carte sera ignorée).
String? _normalizeRarity(String raw) {
  // 1) Strip étoile foil/parallel (ex `R★` → `R`) et nettoyage espaces.
  final cleaned = raw.replaceAll('★', '').replaceAll('*', '').trim().toUpperCase();
  switch (cleaned) {
    case 'L':
      return 'L';
    case 'C':
      return 'C';
    case 'UC':
      return 'UC';
    case 'R':
      return 'R';
    case 'SR':
      return 'SR';
    case 'SEC':
    case 'SECRET RARE':
      return 'SEC';
    case 'DON':
    case 'DON!!':
    case 'DON !!':
      return 'DON';
    case 'P':
    case 'PROMO':
      return 'P';
    case 'SP':
    case 'SP CARD':
    case 'SPECIAL':
    case 'SPECIAL CARD':
      return 'SP';
    case 'TR':
    case 'TREASURE':
    case 'TREASURE RARE':
      return 'TR';
    default:
      return null;
  }
}

/// Mappe un suffixe de variant Bandai vers un libellé humain.
/// `_p1` → `Alt Art` · `_p2` → `Alt Art 2` · `_r1` → `Reprint` · `_r2` → `Reprint 2`
String? _variantLabelFor(String? suffix) {
  if (suffix == null) return null;
  final lower = suffix.toLowerCase();
  if (lower.length < 3) return null;
  final kind = lower.substring(0, 2); // '_p' ou '_r'
  final n = lower.substring(2);
  if (kind == '_p') return n == '1' ? 'Alt Art' : 'Alt Art $n';
  if (kind == '_r') return n == '1' ? 'Reprint' : 'Reprint $n';
  return null;
}

String? _normalizeCardType(String raw) {
  switch (raw.toUpperCase()) {
    case 'LEADER':
      return 'Leader';
    case 'CHARACTER':
      return 'Character';
    case 'EVENT':
      return 'Event';
    case 'STAGE':
      return 'Stage';
    case 'DON!!':
    case 'DON !!':
    case 'DON':
      return null; // Don!! n'est pas un card_type au sens strict
    default:
      return null;
  }
}

/// Upsert d'un batch dans une table Supabase via PostgREST.
Future<void> _supabaseUpsert({
  required http.Client client,
  required String supabaseUrl,
  required String serviceRoleKey,
  required String table,
  required List<Map<String, dynamic>> rows,
  required String onConflict,
}) async {
  if (rows.isEmpty) return;
  final url = '$supabaseUrl/rest/v1/$table?on_conflict=$onConflict';
  final response = await client.post(
    Uri.parse(url),
    headers: {
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
      'Content-Type': 'application/json',
      'Prefer': 'resolution=merge-duplicates,return=minimal',
    },
    body: jsonEncode(rows),
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError(
      'Upsert échoué sur $table : HTTP ${response.statusCode} — ${response.body}',
    );
  }
}

Future<void> main(List<String> args) async {
  // Charge .env
  final env = _readDotEnv(File('.env'));
  final supabaseUrl = env['SUPABASE_URL'];
  final serviceRoleKey = env['SUPABASE_SERVICE_ROLE_KEY'];
  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    stderr.writeln('❌ SUPABASE_URL absent de .env');
    exit(1);
  }
  if (serviceRoleKey == null || serviceRoleKey.isEmpty) {
    stderr.writeln(
      '❌ SUPABASE_SERVICE_ROLE_KEY absent de .env\n'
      '   Récupère-le dans Supabase Dashboard → Settings → API → service_role',
    );
    exit(1);
  }

  final client = http.Client();
  final allCards = <_ParsedCard>[];

  print('━━━ Récupération du catalogue Bandai ━━━');
  for (final entry in _seriesIds.entries) {
    final seriesId = entry.key;
    final label = entry.value;
    stdout.write('• $label … ');
    try {
      final parsed = await _fetchSet(seriesId, label, client);
      allCards.addAll(parsed);
      print('${parsed.length} cartes');
    } catch (e) {
      print('échec : $e');
    }
    // Politesse : 200 ms entre les requêtes pour ne pas surcharger Bandai.
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  print('\n━━━ Total parsé : ${allCards.length} entrées ━━━\n');
  if (allCards.isEmpty) {
    stderr.writeln('Aucune carte récupérée — abandon.');
    exit(1);
  }

  // Dedup des cartes de base (par baseCode)
  final basesByCode = <String, _ParsedCard>{};
  for (final c in allCards) {
    if (c.variantSuffix != null) continue;
    basesByCode.putIfAbsent(c.baseCode, () => c);
  }

  // Si certaines cartes ont uniquement des alt-arts visibles (rare), on prend
  // l'alt comme représentatif de la base (on ne peut pas faire mieux sans la
  // base).
  for (final c in allCards) {
    basesByCode.putIfAbsent(c.baseCode, () => c);
  }

  final cardRows = basesByCode.values
      .map((c) => <String, dynamic>{
            'set_code': c.setCode,
            'card_number': c.cardNumber,
            'name': c.name,
            'rarity': c.rarity,
            'colors': c.colors,
            if (c.cardType != null) 'card_type': c.cardType,
            'image_url': c.imageUrl,
          })
      .toList();

  print('• Upsert ${cardRows.length} cartes dans `cards` …');
  // Chunk pour rester sous la taille max d'une requête PostgREST.
  for (final batch in _chunk(cardRows, 200)) {
    await _supabaseUpsert(
      client: client,
      supabaseUrl: supabaseUrl,
      serviceRoleKey: serviceRoleKey,
      table: 'cards',
      rows: batch,
      onConflict: 'set_code,card_number',
    );
    stdout.write('.');
  }
  print('\n  ✓ cards upsertées');

  // Récupère les UUIDs des cartes que l'on vient d'insérer pour pouvoir
  // construire les variants.
  final cardIds = await _fetchCardIds(
    client: client,
    supabaseUrl: supabaseUrl,
    serviceRoleKey: serviceRoleKey,
  );
  print('• ${cardIds.length} card_id récupérés');

  // Dedup par (card_id, is_foil, is_alt_art, variant_label) — Bandai liste
  // parfois la même variante dans plusieurs séries (ex : promo réimprimé).
  // PostgreSQL refuse un upsert qui matche la même contrainte deux fois.
  final variantRowsByKey = <String, Map<String, dynamic>>{};
  for (final c in allCards) {
    final cardId = cardIds[c.baseCode];
    if (cardId == null) continue;
    final variantLabel = _variantLabelFor(c.variantSuffix);
    final key = '$cardId|false|${c.isAltArt}|${variantLabel ?? ''}';
    variantRowsByKey[key] = {
      'card_id': cardId,
      'is_foil': false,
      'is_alt_art': c.isAltArt,
      'variant_label': variantLabel,
      'image_url': c.imageUrl,
    };
  }
  final variantRows = variantRowsByKey.values.toList();

  print('• Upsert ${variantRows.length} variants dans `card_variants` …');
  for (final batch in _chunk(variantRows, 200)) {
    await _supabaseUpsert(
      client: client,
      supabaseUrl: supabaseUrl,
      serviceRoleKey: serviceRoleKey,
      table: 'card_variants',
      rows: batch,
      // Index unique : (card_id, is_foil, is_alt_art, coalesce(variant_label, ''))
      onConflict: 'card_id,is_foil,is_alt_art,variant_label',
    );
    stdout.write('.');
  }
  print('\n  ✓ card_variants upsertés');

  client.close();
  print('\n✅ Import terminé.');
}

Iterable<List<T>> _chunk<T>(List<T> list, int size) sync* {
  for (var i = 0; i < list.length; i += size) {
    yield list.sublist(i, i + size > list.length ? list.length : i + size);
  }
}

Future<Map<String, String>> _fetchCardIds({
  required http.Client client,
  required String supabaseUrl,
  required String serviceRoleKey,
}) async {
  final result = <String, String>{};
  // Pagination PostgREST (1000 lignes max par défaut).
  var from = 0;
  const pageSize = 1000;
  while (true) {
    final url = '$supabaseUrl/rest/v1/cards?select=id,code';
    final response = await client.get(
      Uri.parse(url),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Range-Unit': 'items',
        'Range': '$from-${from + pageSize - 1}',
      },
    );
    if (response.statusCode >= 300 && response.statusCode != 206) {
      throw StateError('Fetch cards : HTTP ${response.statusCode} — ${response.body}');
    }
    final List<dynamic> rows = jsonDecode(response.body) as List<dynamic>;
    if (rows.isEmpty) break;
    for (final row in rows) {
      final m = row as Map<String, dynamic>;
      result[m['code'] as String] = m['id'] as String;
    }
    if (rows.length < pageSize) break;
    from += pageSize;
  }
  return result;
}
