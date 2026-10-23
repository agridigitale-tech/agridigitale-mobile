import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../models/bulletin_meteo.dart';

/// Widget de carte géographique interactive du Togo avec les 5 régions administratives
class TogoMapWidget extends StatefulWidget {
  final List<RegionMeteo> regions;
  final Function(RegionMeteo) onRegionSelected;
  final String? codeRegionSelectionnee;

  const TogoMapWidget({
    super.key,
    required this.regions,
    required this.onRegionSelected,
    this.codeRegionSelectionnee,
  });

  @override
  State<TogoMapWidget> createState() => _TogoMapWidgetState();
}

class _TogoMapWidgetState extends State<TogoMapWidget> {
  late String _activeCode;

  @override
  void initState() {
    super.initState();
    _activeCode = widget.codeRegionSelectionnee ??
        (widget.regions.isNotEmpty ? widget.regions.last.code : 'maritime');
  }

  @override
  void didUpdateWidget(covariant TogoMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.codeRegionSelectionnee != null &&
        widget.codeRegionSelectionnee != _activeCode) {
      setState(() => _activeCode = widget.codeRegionSelectionnee!);
    }
  }

  RegionMeteo? get _regionActive {
    return widget.regions.firstWhere(
      (r) => r.code == _activeCode,
      orElse: () => widget.regions.isNotEmpty ? widget.regions.last : BulletinMeteo.regionsParDefaut.last,
    );
  }

  IconData _getIconData(String icone) {
    switch (icone.toLowerCase()) {
      case 'soleil':
        return Icons.wb_sunny_rounded;
      case 'eclaircie':
        return Icons.cloud_queue_rounded;
      case 'orage':
        return Icons.thunderstorm_rounded;
      case 'pluie':
        return Icons.water_drop_rounded;
      case 'nuage':
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  Color _getIconColor(String icone, bool isDark) {
    switch (icone.toLowerCase()) {
      case 'soleil':
        return Colors.orangeAccent;
      case 'orage':
        return Colors.amber.shade700;
      case 'pluie':
        return Colors.blueAccent;
      case 'eclaircie':
        return isDark ? Colors.lightBlueAccent : Colors.blueGrey;
      default:
        return isDark ? AppColors.texteSombreMoyen : Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceSombre : Colors.white;
    final borderColor = isDark ? AppColors.bordureSombre : const Color(0xFFE8E8E8);
    final region = _regionActive;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la carte
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.vertClair.withValues(alpha: 0.15)
                      : AppColors.vertPrimaire.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.map_outlined,
                  color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carte Agro-Météorologique du Togo',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.texteSombreFort : AppColors.texteFort,
                      ),
                    ),
                    Text(
                      'Touchez une région pour afficher ses prévisions',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Zone Carte du Togo et Liste interactive
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Silhouette stylisée et interactive du Togo (Nord -> Sud)
              SizedBox(
                width: 95,
                height: 290,
                child: CustomPaint(
                  painter: _TogoMapPainter(
                    activeCode: _activeCode,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Liste des 5 régions géographiques (du Nord au Sud)
              Expanded(
                child: Column(
                  children: widget.regions.map((r) {
                    final isSelected = r.code == _activeCode;
                    final iconColor = _getIconColor(r.icone, isDark);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: InkWell(
                        onTap: () {
                          setState(() => _activeCode = r.code);
                          widget.onRegionSelected(r);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.vertClair.withValues(alpha: 0.18)
                                    : AppColors.vertPrimaire.withValues(alpha: 0.1))
                                : (isDark
                                    ? AppColors.surfaceSombreLegere.withValues(alpha: 0.4)
                                    : const Color(0xFFF9FAF9)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                  : (isDark ? AppColors.bordureSombre : const Color(0xFFEEEEEE)),
                              width: isSelected ? 1.6 : 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(_getIconData(r.icone), size: 20, color: iconColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.nom,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected
                                            ? (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                            : (isDark ? AppColors.texteSombreFort : AppColors.texteFort),
                                      ),
                                    ),
                                    Text(
                                      r.chefLieu.split('(').first.trim(),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${r.tempMax.toInt()}°C',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                      : (isDark ? AppColors.texteSombreFort : AppColors.texteFort),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          // Fiche détaillée de la région sélectionnée
          if (region != null) ...[
            const SizedBox(height: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceSombreLegere : const Color(0xFFF4F9F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.vertClair.withValues(alpha: 0.3)
                      : AppColors.vertPrimaire.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIconData(region.icone),
                        color: _getIconColor(region.icone, isDark),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Région ${region.nom} — ${region.chefLieu}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.texteSombreFort : AppColors.vertFonce,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${region.tempMin.toInt()}°C – ${region.tempMax.toInt()}°C',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    region.condition,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.texteSombreFort : Colors.black87,
                    ),
                  ),
                  if (region.conseil.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.eco_outlined, size: 14, color: AppColors.vertPrimaire),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            region.conseil,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: isDark ? AppColors.texteSombreMoyen : Colors.grey.shade700,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// CustomPainter dessinant la forme géographique stylisée des 5 régions du Togo du Nord au Sud
class _TogoMapPainter extends CustomPainter {
  final String activeCode;
  final bool isDark;

  _TogoMapPainter({required this.activeCode, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Palette de base
    final defaultRegionColor = isDark ? const Color(0xFF242A36) : const Color(0xFFE2EBE4);
    final activeRegionColor = isDark ? AppColors.vertClair : AppColors.vertPrimaire;
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF3B4354) : const Color(0xFFC7D7CA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final activeBorderPaint = Paint()
      ..color = isDark ? Colors.white : AppColors.vertFonce
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 1. SAVANES (Nord) - Découpage Y: 0.0 -> 0.18
    _drawRegion(
      canvas: canvas,
      code: 'savanes',
      path: Path()
        ..moveTo(w * 0.18, 0)
        ..lineTo(w * 0.82, 0)
        ..lineTo(w * 0.88, h * 0.18)
        ..lineTo(w * 0.12, h * 0.18)
        ..close(),
      defaultColor: defaultRegionColor,
      activeColor: activeRegionColor,
      borderPaint: borderPaint,
      activeBorderPaint: activeBorderPaint,
      label: 'SAVANES',
      center: Offset(w * 0.5, h * 0.09),
    );

    // 2. KARA (Nord-Centre) - Découpage Y: 0.18 -> 0.38
    _drawRegion(
      canvas: canvas,
      code: 'kara',
      path: Path()
        ..moveTo(w * 0.12, h * 0.18)
        ..lineTo(w * 0.88, h * 0.18)
        ..lineTo(w * 0.94, h * 0.38)
        ..lineTo(w * 0.10, h * 0.38)
        ..close(),
      defaultColor: defaultRegionColor,
      activeColor: activeRegionColor,
      borderPaint: borderPaint,
      activeBorderPaint: activeBorderPaint,
      label: 'KARA',
      center: Offset(w * 0.5, h * 0.28),
    );

    // 3. CENTRALE (Centre) - Découpage Y: 0.38 -> 0.58
    _drawRegion(
      canvas: canvas,
      code: 'centrale',
      path: Path()
        ..moveTo(w * 0.10, h * 0.38)
        ..lineTo(w * 0.94, h * 0.38)
        ..lineTo(w * 0.98, h * 0.58)
        ..lineTo(w * 0.08, h * 0.58)
        ..close(),
      defaultColor: defaultRegionColor,
      activeColor: activeRegionColor,
      borderPaint: borderPaint,
      activeBorderPaint: activeBorderPaint,
      label: 'CENTRALE',
      center: Offset(w * 0.5, h * 0.48),
    );

    // 4. PLATEAUX (Sud-Centre, zone la plus large) - Découpage Y: 0.58 -> 0.80
    _drawRegion(
      canvas: canvas,
      code: 'plateaux',
      path: Path()
        ..moveTo(w * 0.08, h * 0.58)
        ..lineTo(w * 0.98, h * 0.58)
        ..lineTo(w * 0.90, h * 0.80)
        ..lineTo(w * 0.05, h * 0.80)
        ..close(),
      defaultColor: defaultRegionColor,
      activeColor: activeRegionColor,
      borderPaint: borderPaint,
      activeBorderPaint: activeBorderPaint,
      label: 'PLATEAUX',
      center: Offset(w * 0.5, h * 0.69),
    );

    // 5. MARITIME (Sud, Côte Atlantique / Lomé) - Découpage Y: 0.80 -> 1.00
    _drawRegion(
      canvas: canvas,
      code: 'maritime',
      path: Path()
        ..moveTo(w * 0.05, h * 0.80)
        ..lineTo(w * 0.90, h * 0.80)
        ..lineTo(w * 0.70, h * 1.00)
        ..lineTo(w * 0.25, h * 1.00)
        ..close(),
      defaultColor: defaultRegionColor,
      activeColor: activeRegionColor,
      borderPaint: borderPaint,
      activeBorderPaint: activeBorderPaint,
      label: 'MARITIME',
      center: Offset(w * 0.48, h * 0.90),
    );

    // Repère Côte / Golfe de Guinée au Sud
    final oceanPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(w * 0.20, h * 1.00 + 3), Offset(w * 0.75, h * 1.00 + 3), oceanPaint);
  }

  void _drawRegion({
    required Canvas canvas,
    required String code,
    required Path path,
    required Color defaultColor,
    required Color activeColor,
    required Paint borderPaint,
    required Paint activeBorderPaint,
    required String label,
    required Offset center,
  }) {
    final isSelected = activeCode == code;
    final fillPaint = Paint()
      ..color = isSelected ? activeColor : defaultColor
      ..style = PaintingStyle.fill;

    // Ombre douce si active
    if (isSelected) {
      canvas.drawShadow(path, activeColor, 6, false);
    }

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, isSelected ? activeBorderPaint : borderPaint);

    // Nom abrégé centré sur la région
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark ? const Color(0xFFBAC3D6) : const Color(0xFF38473D)),
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant _TogoMapPainter oldDelegate) {
    return oldDelegate.activeCode != activeCode || oldDelegate.isDark != isDark;
  }
}
