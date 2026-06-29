import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import '../providers/location_provider.dart';

class GPSYardageCard extends ConsumerStatefulWidget {
  final double? courseLatitude;
  final double? courseLongitude;
  final int holeNumber;
  final int par;
  final int? teeDistance;

  const GPSYardageCard({
    super.key,
    required this.courseLatitude,
    required this.courseLongitude,
    required this.holeNumber,
    required this.par,
    this.teeDistance,
  });

  @override
  ConsumerState<GPSYardageCard> createState() => _GPSYardageCardState();
}

class _GPSYardageCardState extends ConsumerState<GPSYardageCard> {
  bool _isSimulating = false;
  double _simulatedDistanceYards = 280;

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationStreamProvider);
    final courseLat = widget.courseLatitude ?? -1.2989; // Default Royal Nairobi
    final courseLng = widget.courseLongitude ?? 36.7914;

    // Project Green location based on hole number (sequential layout from clubhouse)
    final greenLat = courseLat + (widget.holeNumber * 0.0003);
    final greenLng = courseLng + (widget.holeNumber * 0.0003);

    return locationAsync.when(
      data: (pos) {
        double centerDistance;

        if (_isSimulating || pos == null) {
          centerDistance = _simulatedDistanceYards;
        } else {
          final meters = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            greenLat,
            greenLng,
          );
          centerDistance = meters * 1.09361; // convert to yards
        }

        // Clamp distance to reasonable golf yardages
        if (centerDistance > 600) {
          centerDistance = (widget.teeDistance ?? 380).toDouble();
        }

        final frontDistance = (centerDistance - 12).round();
        final centerDistRound = centerDistance.round();
        final backDistance = (centerDistance + 12).round();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.grey900,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.grey900.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.navigation, color: AppColors.golfLime, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE GPS RANGEFINDER',
                        style: TextStyle(
                          color: AppColors.golfLime,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (!_isSimulating) {
                          _isSimulating = true;
                          _simulatedDistanceYards = (widget.teeDistance ?? 380).toDouble();
                        } else {
                          _simulatedDistanceYards -= 40;
                          if (_simulatedDistanceYards < 10) {
                            _isSimulating = false;
                          }
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isSimulating ? AppColors.golfLime.withValues(alpha: 0.2) : AppColors.grey800,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isSimulating ? 'SIMULATING (-40y)' : 'SIMULATE',
                        style: TextStyle(
                          color: _isSimulating ? AppColors.golfLime : AppColors.grey400,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDistanceColumn('FRONT', '$frontDistance', AppColors.grey400),
                  _buildDistanceColumn('CENTER', '$centerDistRound', AppColors.golfLime, isMain: true),
                  _buildDistanceColumn('BACK', '$backDistance', AppColors.grey400),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.grey800, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Target: Green Center • Par ${widget.par}',
                    style: const TextStyle(color: AppColors.grey500, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  GestureDetector(
                    onTap: () => _showHoleMap(context),
                    child: Row(
                      children: const [
                        Text(
                          'View Hole Map',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        Icon(LucideIcons.chevronRight, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _buildPlaceholderCard('Connecting GPS satellites...'),
      error: (e, _) => _buildPlaceholderCard('GPS connection failed. Enable location.'),
    );
  }

  Widget _buildPlaceholderCard(String message) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.satellite, color: AppColors.golfLime, size: 28),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: AppColors.grey400, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceColumn(String label, String value, Color color, {bool isMain = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.grey500, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isMain ? 48 : 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const Text(
          'YARDS',
          style: TextStyle(color: AppColors.grey600, fontSize: 9, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  void _showHoleMap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HoleMapBottomSheet(
        holeNumber: widget.holeNumber,
        par: widget.par,
        distanceYards: _isSimulating ? _simulatedDistanceYards.round() : 180,
      ),
    );
  }
}

class _HoleMapBottomSheet extends StatelessWidget {
  final int holeNumber;
  final int par;
  final int distanceYards;

  const _HoleMapBottomSheet({
    required this.holeNumber,
    required this.par,
    required this.distanceYards,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOLE $holeNumber MAP',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5),
                  ),
                  Text(
                    'Par $par • $distanceYards yards to green center',
                    style: const TextStyle(fontSize: 13, color: AppColors.grey500, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: AppColors.grey900),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.grey50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Custom Painted Vector Golf Hole
          Container(
            height: 360,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.green.shade100, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: _GolfHolePainter(distanceYards: distanceYards),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(Colors.green.shade700, 'Green'),
              _buildLegendItem(Colors.green.shade400, 'Fairway'),
              _buildLegendItem(AppColors.golfSand, 'Bunker'),
              _buildLegendItem(AppColors.blue600, 'Water'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey700),
        ),
      ],
    );
  }
}

class _GolfHolePainter extends CustomPainter {
  final int distanceYards;

  _GolfHolePainter({required this.distanceYards});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw rough background
    final roughPaint = Paint()..color = Colors.green.shade100;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), roughPaint);

    // Draw Fairway (a winding light-green path)
    final fairwayPaint = Paint()
      ..color = Colors.green.shade300
      ..style = PaintingStyle.fill;
    
    final fairwayPath = Path()
      ..moveTo(width * 0.5, height * 0.9) // Tee box area
      ..quadraticBezierTo(width * 0.4, height * 0.6, width * 0.6, height * 0.45)
      ..quadraticBezierTo(width * 0.7, height * 0.3, width * 0.5, height * 0.15) // Green area
      ..lineTo(width * 0.35, height * 0.15)
      ..quadraticBezierTo(width * 0.5, height * 0.3, width * 0.4, height * 0.45)
      ..quadraticBezierTo(width * 0.25, height * 0.6, width * 0.35, height * 0.9)
      ..close();
    canvas.drawPath(fairwayPath, fairwayPaint);

    // Draw Hazards/Bunkers
    final sandPaint = Paint()
      ..color = AppColors.golfSand
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(width * 0.62, height * 0.42), width: 28, height: 16), sandPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(width * 0.36, height * 0.22), width: 20, height: 12), sandPaint);

    // Draw Water Hazard (left side of fairway approach)
    final waterPaint = Paint()
      ..color = AppColors.blue600.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    
    final waterPath = Path()
      ..moveTo(0, height * 0.5)
      ..quadraticBezierTo(width * 0.2, height * 0.48, width * 0.25, height * 0.58)
      ..quadraticBezierTo(width * 0.2, height * 0.68, 0, height * 0.65)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    // Draw Green (a dark green oval)
    final greenPaint = Paint()
      ..color = Colors.green.shade700
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(width * 0.5, height * 0.16), width: 50, height: 40), greenPaint);

    // Draw Flagstick & Flag
    final flagstickPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(width * 0.5, height * 0.18), Offset(width * 0.5, height * 0.1), flagstickPaint);

    final flagPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final flagPath = Path()
      ..moveTo(width * 0.5, height * 0.1)
      ..lineTo(width * 0.58, height * 0.12)
      ..lineTo(width * 0.5, height * 0.14)
      ..close();
    canvas.drawPath(flagPath, flagPaint);

    // Draw Tee box
    final teeBoxPaint = Paint()
      ..color = AppColors.grey800
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromCenter(center: Offset(width * 0.45, height * 0.88), width: 32, height: 12), teeBoxPaint);

    // Draw Player Location (if distance is less than tee yardage, show relative approach)
    final playerPaint = Paint()
      ..color = AppColors.blue700
      ..style = PaintingStyle.fill;
    
    // Scale player position: at 380y player is at tee box, at 0y player is at green center
    double relativePosPercent = (distanceYards / 380.0).clamp(0.0, 1.0);
    double playerX = width * 0.45 + (width * 0.5 - width * 0.45) * (1 - relativePosPercent);
    double playerY = height * 0.88 + (height * 0.16 - height * 0.88) * (1 - relativePosPercent);

    canvas.drawCircle(Offset(playerX, playerY), 6.0, playerPaint);
    
    final playerGlowPaint = Paint()
      ..color = AppColors.blue600.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(playerX, playerY), 12.0, playerGlowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
