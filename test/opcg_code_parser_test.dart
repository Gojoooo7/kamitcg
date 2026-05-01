import 'package:flutter_test/flutter_test.dart';
import 'package:kamitcg/features/scanner/domain/opcg_code_parser.dart';

void main() {
  group('OpcgCodeParser.tryExtract', () {
    test('matche un code OP simple', () {
      expect(OpcgCodeParser.tryExtract('OP01-120'), 'OP01-120');
    });

    test('matche un code ST simple', () {
      expect(OpcgCodeParser.tryExtract('ST01-007'), 'ST01-007');
    });

    test('matche un code EB simple', () {
      expect(OpcgCodeParser.tryExtract('EB01-006'), 'EB01-006');
    });

    test('matche un code PRB', () {
      expect(OpcgCodeParser.tryExtract('PRB01-001'), 'PRB01-001');
    });

    test('matche un promo P-XXX', () {
      expect(OpcgCodeParser.tryExtract('P-001'), 'P-001');
    });

    test('matche un alt-art _p1 (normalisé en _P1)', () {
      expect(OpcgCodeParser.tryExtract('OP01-051_p1'), 'OP01-051_P1');
    });

    test('matche au milieu de bruit OCR', () {
      const input = '©BANDAI 2024\nOP01-120\nCharlotte Katakuri';
      expect(OpcgCodeParser.tryExtract(input), 'OP01-120');
    });

    test('insensible à la casse (normalisation upper)', () {
      expect(OpcgCodeParser.tryExtract('op01-120'), 'OP01-120');
    });

    test('rejette un préfixe inconnu (XX1-001)', () {
      expect(OpcgCodeParser.tryExtract('XX1-001 noise'), isNull);
    });

    test('rejette un code à 4 chiffres (numérotation invalide)', () {
      expect(OpcgCodeParser.tryExtract('OP01-1200'), isNull);
    });

    test('rejette un code à 2 chiffres (numérotation invalide)', () {
      expect(OpcgCodeParser.tryExtract('OP01-12'), isNull);
    });

    test('extractAll retourne plusieurs codes uniques', () {
      const input = 'OP01-001\nOP01-001\nST01-007\nP-001';
      expect(
        OpcgCodeParser.extractAll(input),
        ['OP01-001', 'ST01-007', 'P-001'],
      );
    });

    test('rejette texte sans code', () {
      expect(
        OpcgCodeParser.tryExtract('Roronoa Zoro / Leader / Power 5000'),
        isNull,
      );
    });
  });
}
