import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/groq_receipt_parser.dart';
import '../../data/ocr_service.dart';
import '../../data/receipt_capture_service.dart';
import '../bloc/scan_bloc.dart';
import '../bloc/scan_event.dart';
import '../bloc/scan_state.dart';
import '../widgets/receipt_review_card.dart';

// Approximate height of _ThermalReceipt widget — used for scan-line positioning.
const _kReceiptH = 302.0;

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScanBloc(
        getIt<ReceiptCaptureService>(),
        getIt<OcrService>(),
        getIt<GroqReceiptParser>(),
      ),
      child: const _ScanView(),
    );
  }
}

class _ScanView extends StatelessWidget {
  const _ScanView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan a receipt'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: BlocConsumer<ScanBloc, ScanState>(
        listener: (context, state) {
          if (state is ScanIdle && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if (state is ScanProcessing) return _ProcessingView(image: state.image);
          if (state is ScanParsed) {
            return ReceiptReviewCard(
              result: state.result,
              image: state.image,
              onRetake: () =>
                  context.read<ScanBloc>().add(const RetakeRequested()),
            );
          }
          if (state is ScanError) return _ErrorView(message: state.message);
          return const _IdleView();
        },
      ),
    );
  }
}

// ── Idle ──────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 96,
            height: 96,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              size: 44,
              color: AppColors.orange,
            ),
          ),
          Center(
            child: Text(
              'Snap a receipt',
              style: AppTypography.headingLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "We'll read it and fill in the details.",
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context
                .read<ScanBloc>()
                .add(const CaptureRequested(CaptureSource.camera)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.paper,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Open camera',
                  style: AppTypography.label.copyWith(
                    color: AppColors.paper,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context
                .read<ScanBloc>()
                .add(const CaptureRequested(CaptureSource.gallery)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.borderSoft),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Choose from gallery',
                  style: AppTypography.label.copyWith(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/transactions/add'),
            child: Text(
              'Enter manually',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Processing (thermal receipt print animation) ───────────────

class _ProcessingView extends StatefulWidget {
  // image kept for API compatibility; the thermal animation replaces the dimmed photo.
  final dynamic image;
  const _ProcessingView({required this.image});

  @override
  State<_ProcessingView> createState() => _ProcessingViewState();
}

class _ProcessingViewState extends State<_ProcessingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    // Linear print 0→78 % of the cycle, then hold full for the remaining 22 %.
    _progress = _ctrl.drive(CurveTween(curve: const _PrintCurve()));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: AppColors.ink,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fixed-height container so the "Reading…" text below doesn't jump.
            SizedBox(
              height: _kReceiptH,
              width: _ThermalReceipt.kReceiptW,
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, child) {
                  final t = _progress.value;
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Receipt revealed top → bottom
                      ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: t.clamp(0.0001, 1.0),
                          child: child,
                        ),
                      ),
                      // Orange print-head scan line
                      if (t > 0.02 && t < 0.97)
                        Positioned(
                          top: (_kReceiptH * t - 1.5)
                              .clamp(0.0, _kReceiptH - 3.0),
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.orange.withValues(alpha: 0.55),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
                child: const _ThermalReceipt(),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Reading receipt…',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                color: AppColors.paper.withValues(alpha: 0.55),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Linear 0→1 over the first 78 % of the repeat cycle, then hold at 1.
class _PrintCurve extends Curve {
  const _PrintCurve();

  @override
  double transformInternal(double t) {
    const printEnd = 0.78;
    return t <= printEnd ? t / printEnd : 1.0;
  }
}

// ── Thermal receipt widget ─────────────────────────────────────

class _ThermalReceipt extends StatelessWidget {
  const _ThermalReceipt();

  static const kReceiptW = 172.0;
  static const _hPad = 16.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kReceiptW,
      child: Stack(
        children: [
          // Paper body — torn bottom edge via clip
          ClipPath(
            clipper: _TornBottomClipper(),
            child: ColoredBox(
              color: AppColors.paper,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 22),
                    // ── Header ────────────────────────────────
                    Text(
                      'SPENDSNAP',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: 2.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DashedDivider(color: AppColors.ink.withValues(alpha: 0.25)),
                    const SizedBox(height: 12),
                    // ── Line items ────────────────────────────
                    const _ReceiptRow('Coffee', '₹4.50'),
                    const SizedBox(height: 7),
                    const _ReceiptRow('Lunch', '₹12.80'),
                    const SizedBox(height: 7),
                    const _ReceiptRow('Transit', '₹2.90'),
                    const SizedBox(height: 12),
                    _DashedDivider(color: AppColors.ink.withValues(alpha: 0.45)),
                    const SizedBox(height: 16),
                    // ── Hero $S glyph ─────────────────────────
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: '\$',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 52,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                            height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: 'S',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 52,
                            fontWeight: FontWeight.w500,
                            color: AppColors.orange,
                            height: 1.1,
                          ),
                        ),
                      ]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    _DashedDivider(color: AppColors.ink.withValues(alpha: 0.25)),
                    const SizedBox(height: 12),
                    // ── Footer ────────────────────────────────
                    Text(
                      'THANKS · COME AGAIN',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        color: AppColors.ink.withValues(alpha: 0.5),
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // ── Barcode ───────────────────────────────
                    const Center(
                      child: SizedBox(
                        width: 106,
                        height: 20,
                        child: CustomPaint(
                          painter: _BarcodePainter(AppColors.ink),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), // space for torn edge
                  ],
                ),
              ),
            ),
          ),
          // Perforation dots on left/right edges
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PerforationsPainter(AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  final Color color;
  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 1.5,
        width: double.infinity,
        child: CustomPaint(painter: _DashedLinePainter(color)),
      );
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dw = 3.0, gap = 3.0;
    final cy = size.height / 2;
    double x = 0;
    while (x < size.width) {
      final x2 = (x + dw).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, cy), Offset(x2, cy), paint);
      x += dw + gap;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.jetBrainsMono(
      fontSize: 10,
      color: AppColors.ink.withValues(alpha: 0.75),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}

class _BarcodePainter extends CustomPainter {
  final Color inkColor;
  const _BarcodePainter(this.inkColor);

  static const _w = [2, 1, 3, 1, 2, 4, 1, 2, 3, 1, 2, 1, 3, 2, 1, 4, 1, 2];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = inkColor;
    final total = _w.fold(0, (a, b) => a + b).toDouble();
    final unit = size.width / total;
    double x = 0;
    for (var i = 0; i < _w.length; i++) {
      final bw = _w[i] * unit;
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(x, 0, bw, size.height), paint);
      }
      x += bw;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Zig-zag clip that gives the receipt a torn-paper bottom edge.
class _TornBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const teeth = 10;
    const depth = 7.0;
    final tornY = size.height - depth;
    final tw = size.width / teeth;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, tornY);

    for (var i = 0; i < teeth; i++) {
      path
        ..lineTo(size.width - tw * (i + 0.5), tornY + depth)
        ..lineTo(size.width - tw * (i + 1), tornY);
    }

    return path..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> _) => false;
}

/// Half-circle punch holes along the left/right edges of the receipt tape.
class _PerforationsPainter extends CustomPainter {
  final Color inkColor;
  const _PerforationsPainter(this.inkColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = inkColor.withValues(alpha: 0.30);
    const r = 3.0, spacing = 20.0;
    double y = 26;
    while (y < size.height - 30) {
      canvas.drawCircle(Offset(0, y), r, paint);
      canvas.drawCircle(Offset(size.width, y), r, paint);
      y += spacing;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Error ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.error_outline,
            size: 56,
            color: AppColors.danger,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () =>
                context.read<ScanBloc>().add(const RetakeRequested()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.paper,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Retry'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/transactions/add'),
            child: const Text('Enter manually'),
          ),
        ],
      ),
    );
  }
}
