import 'dart:async';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/card_art.dart';
import '../../../core/widgets/delta_badge.dart';
import '../../portfolio/presentation/portfolio_providers.dart';
import '../data/ocr_service.dart';

/// Phase d'UI du scanner.
enum _ScanPhase { initializing, scanning, matched, denied }

/// Écran scanner OCR — caméra arrière + ML Kit Text Recognition (local).
///
/// Pas de stockage d'image ni de texte, conformément à CLAUDE.md (privacy first).
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({
    required this.onClose,
    required this.onAdded,
    required this.onManualEntry,
    super.key,
  });

  final VoidCallback onClose;
  final ValueChanged<CatalogueEntry> onAdded;
  final VoidCallback onManualEntry;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _camera;
  late final OcrService _ocr;
  late final AnimationController _beam;

  _ScanPhase _phase = _ScanPhase.initializing;
  CatalogueEntry? _matched;
  bool _adding = false;
  DateTime _lastScanAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ocr = OcrService();
    _beam = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _camera = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      await _camera!.initialize();
      if (!mounted) return;
      setState(() => _phase = _ScanPhase.scanning);
      await _camera!.startImageStream(_onFrame);
    } on CameraException catch (e) {
      if (!mounted) return;
      // Permission refusée ou caméra indisponible.
      setState(() => _phase = _ScanPhase.denied);
      debugPrint('Camera init failed: ${e.code} ${e.description}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _phase = _ScanPhase.denied);
    }
  }

  /// Traite une frame caméra. Throttlé à ~3 scans/seconde max.
  Future<void> _onFrame(CameraImage image) async {
    if (_phase != _ScanPhase.scanning) return;
    final now = DateTime.now();
    if (now.difference(_lastScanAt).inMilliseconds < 300) return;
    _lastScanAt = now;

    final inputImage = _toInputImage(image, _camera!.description);
    if (inputImage == null) return;

    final code = await _ocr.scanFrame(inputImage);
    if (code == null || !mounted) return;

    final repo = ref.read(cardRepositoryProvider);
    final found = await repo.findEntryByCode(code);
    if (!mounted) return;

    if (found == null) {
      // Code lu mais pas dans le catalogue. Snackbar discret, on continue.
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.info(Strings.scannerNotInCatalogue),
      );
      return;
    }

    // Match — on stoppe le stream pour libérer le CPU pendant la modale.
    HapticFeedback.mediumImpact();
    await _camera?.stopImageStream();
    if (!mounted) return;
    setState(() {
      _phase = _ScanPhase.matched;
      _matched = CatalogueEntry(card: found.card, variant: found.variant);
    });
  }

  Future<void> _resumeScan() async {
    if (_camera == null || !_camera!.value.isInitialized) return;
    setState(() {
      _phase = _ScanPhase.scanning;
      _matched = null;
    });
    if (_camera!.value.isStreamingImages) return;
    await _camera!.startImageStream(_onFrame);
  }

  Future<void> _addToCollection() async {
    final entry = _matched;
    if (entry == null) return;
    setState(() => _adding = true);
    try {
      await ref
          .read(collectionRepositoryProvider)
          .addVariantToCollection(entry.variant.id);
      ref.invalidate(collectionProvider);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      widget.onAdded(entry);
    } catch (_) {
      if (!mounted) return;
      setState(() => _adding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(Strings.addCardAddError),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      cam.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _beam.dispose();
    _ocr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          // Couche caméra (ou fond noir tant que pas init / refusé)
          if (_phase != _ScanPhase.denied &&
              _camera != null &&
              _camera!.value.isInitialized)
            Positioned.fill(child: CameraPreview(_camera!))
          else
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 0.7,
                    colors: [Color(0xFF1A1A22), Color(0xFF0A0A0C)],
                    stops: [0, 1],
                  ),
                ),
              ),
            ),
          // Tint noir pour mieux faire ressortir le viewfinder
          const Positioned.fill(
            child: ColoredBox(color: Color(0x66000000)),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(onClose: widget.onClose),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Viewfinder(phase: _phase, beam: _beam),
                        const SizedBox(height: 20),
                        _Hint(phase: _phase),
                      ],
                    ),
                  ),
                ),
                if (_phase == _ScanPhase.matched && _matched != null)
                  _MatchSheet(
                    entry: _matched!,
                    adding: _adding,
                    onSkip: _resumeScan,
                    onAdd: _addToCollection,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: TextButton(
                      onPressed: widget.onManualEntry,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0x33000000),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.line2),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 18,
                        ),
                      ),
                      child: Text(
                        Strings.scannerManualEntry,
                        style: AppTypography.inter(
                          size: 13,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Conversion CameraImage → InputImage selon la plate-forme.
/// Sur Android : `nv21` (1 plane). Sur iOS : `bgra8888` (1 plane).
InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
  final rotation =
      InputImageRotationValue.fromRawValue(camera.sensorOrientation);
  if (rotation == null) return null;
  final rawFormat = image.format.raw;
  if (rawFormat is! int) return null;
  final format = InputImageFormatValue.fromRawValue(rawFormat);
  if (format == null) return null;
  if (image.planes.length != 1) return null;
  final plane = image.planes.first;
  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          Material(
            color: const Color(0x80000000),
            shape:
                const CircleBorder(side: BorderSide(color: AppColors.line2)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
              ),
            ),
          ),
          const Spacer(),
          Text(
            Strings.scannerTitle,
            style: AppTypography.inter(
              size: 13,
              weight: FontWeight.w600,
              color: const Color(0xD9FFFFFF),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.phase, required this.beam});
  final _ScanPhase phase;
  final AnimationController beam;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 336,
      child: Stack(
        children: [
          // Beam (n'apparaît qu'en mode scanning)
          if (phase == _ScanPhase.scanning)
            AnimatedBuilder(
              animation: beam,
              builder: (_, _) => Positioned(
                left: 6,
                right: 6,
                top: 4 + beam.value * 324,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.gold,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(color: AppColors.gold, blurRadius: 14),
                    ],
                  ),
                ),
              ),
            ),
          // Halo doré quand match
          if (phase == _ScanPhase.matched)
            Positioned.fill(
              child: ColoredBox(color: AppColors.gold.withAlpha(0x2E)),
            ),
          // Coins dorés
          ..._corners(),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const size = 28.0;
    const t = 2.5;
    Widget corner(Alignment a, BorderRadiusGeometry radius, Border border) {
      return Align(
        alignment: a,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(border: border, borderRadius: radius),
        ),
      );
    }

    return [
      corner(
        Alignment.topLeft,
        const BorderRadius.only(topLeft: Radius.circular(16)),
        const Border(
          top: BorderSide(color: AppColors.gold, width: t),
          left: BorderSide(color: AppColors.gold, width: t),
        ),
      ),
      corner(
        Alignment.topRight,
        const BorderRadius.only(topRight: Radius.circular(16)),
        const Border(
          top: BorderSide(color: AppColors.gold, width: t),
          right: BorderSide(color: AppColors.gold, width: t),
        ),
      ),
      corner(
        Alignment.bottomLeft,
        const BorderRadius.only(bottomLeft: Radius.circular(16)),
        const Border(
          bottom: BorderSide(color: AppColors.gold, width: t),
          left: BorderSide(color: AppColors.gold, width: t),
        ),
      ),
      corner(
        Alignment.bottomRight,
        const BorderRadius.only(bottomRight: Radius.circular(16)),
        const Border(
          bottom: BorderSide(color: AppColors.gold, width: t),
          right: BorderSide(color: AppColors.gold, width: t),
        ),
      ),
    ];
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.phase});
  final _ScanPhase phase;

  @override
  Widget build(BuildContext context) {
    final (text, color, weight) = switch (phase) {
      _ScanPhase.initializing => (
          Strings.scannerCameraInit,
          const Color(0xB3FFFFFF),
          FontWeight.w500,
        ),
      _ScanPhase.scanning => (
          Strings.scannerAiming,
          const Color(0xB3FFFFFF),
          FontWeight.w500,
        ),
      _ScanPhase.matched => (
          Strings.scannerMatchFound,
          AppColors.gold,
          FontWeight.w600,
        ),
      _ScanPhase.denied => (
          Strings.scannerCameraDenied,
          AppColors.down,
          FontWeight.w500,
        ),
    };
    return SizedBox(
      width: 260,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.inter(size: 13, weight: weight, color: color),
      ),
    );
  }
}

class _MatchSheet extends StatelessWidget {
  const _MatchSheet({
    required this.entry,
    required this.adding,
    required this.onSkip,
    required this.onAdd,
  });

  final CatalogueEntry entry;
  final bool adding;
  final VoidCallback onSkip;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final display = entry.toDisplay();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xEB141418),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CardArtTile(card: display, width: 48, height: 68),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          size: 15,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(entry.card.code,
                              style: AppTypography.mono(size: 11.5)),
                          const Text(' · ',
                              style: TextStyle(color: AppColors.text3)),
                          Text(
                            entry.card.setCode,
                            style: AppTypography.inter(
                              size: 11.5,
                              color: AppColors.text2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const DeltaBadge(
                  value: 0,
                  pct: 0,
                  size: DeltaBadgeSize.sm,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: adding ? null : onSkip,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0x0AFFFFFF),
                        foregroundColor: AppColors.text0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.line2),
                        ),
                      ),
                      child: Text(
                        Strings.scannerSkip,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppColors.text0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 7,
                  child: SizedBox(
                    height: 44,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.gold, AppColors.goldDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withAlpha(0x59),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: adding ? null : onAdd,
                          child: Center(
                            child: adding
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Color(0xFF191100),
                                      ),
                                    ),
                                  )
                                : Text(
                                    Strings.scannerAdd,
                                    style: AppTypography.inter(
                                      size: 13,
                                      weight: FontWeight.w700,
                                      color: const Color(0xFF191100),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

