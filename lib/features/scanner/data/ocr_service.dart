import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../domain/opcg_code_parser.dart';

/// Wrapper minimaliste autour de Google ML Kit Text Recognition.
///
/// Tout le traitement se fait en local (CLAUDE.md : pas de service OCR cloud).
/// Le service n'extrait que les codes OPCG du texte reconnu — il ne stocke ni
/// l'image ni le texte brut.
class OcrService {
  OcrService() : _recognizer = TextRecognizer();

  final TextRecognizer _recognizer;
  bool _processing = false;

  /// Lance la reconnaissance sur [image] et retourne le premier code OPCG
  /// détecté (ex: `OP01-120`), ou null si rien.
  ///
  /// Drop silencieusement les frames quand un scan est déjà en cours, pour
  /// éviter d'empiler des appels concurrents (utilisé via le stream caméra).
  Future<String?> scanFrame(InputImage image) async {
    if (_processing) return null;
    _processing = true;
    try {
      final result = await _recognizer.processImage(image);
      return OpcgCodeParser.tryExtract(result.text);
    } catch (_) {
      // Silencieux : le stream caméra appelle ça en continu, on ne veut pas
      // spammer les logs sur des frames partielles ou corrompues.
      return null;
    } finally {
      _processing = false;
    }
  }

  /// Doit être appelé en `dispose()` du widget consommateur — sinon ML Kit
  /// garde le model en RAM.
  Future<void> dispose() => _recognizer.close();
}
