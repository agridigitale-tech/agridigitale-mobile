import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_parsing/path_parsing.dart';
import '../../../core/design/app_colors.dart';
import '../models/bulletin_meteo.dart';
import 'togo_svg_data.dart';

/// Helper pour convertir une chaîne SVG Path en objet Path Flutter
class _SvgToPathProxy extends PathProxy {
  final Path path;
  _SvgToPathProxy(this.path);

  @override
  void close() => path.close();

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) =>
      path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
}

/// Widget de carte géographique interactive et animée du Togo,
/// basé sur les coordonnées vectorielles réelles de togo.svg
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

  static IconData getIconData(String icone) {
    switch (icone.toLowerCase()) {
      case 'soleil':
      case 'sun':
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'eclaircie':
      case 'partly-cloudy':
        return Icons.cloud_queue_rounded;
      case 'orage':
      case 'thunder':
      case 'storm':
        return Icons.thunderstorm_rounded;
      case 'pluie':
      case 'rain':
      case 'drizzle':
        return Icons.water_drop_rounded;
      case 'nuage':
      case 'cloud':
      case 'cloudy':
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  static Color getIconColor(String icone, bool isDark) {
    switch (icone.toLowerCase()) {
      case 'soleil':
      case 'sun':
      case 'clear':
        return Colors.orangeAccent;
      case 'orage':
      case 'thunder':
      case 'storm':
        return Colors.amber.shade700;
      case 'pluie':
      case 'rain':
      case 'drizzle':
        return Colors.blueAccent;
      case 'eclaircie':
      case 'partly-cloudy':
        return isDark ? Colors.lightBlueAccent : Colors.teal;
      default:
        return isDark ? AppColors.texteSombreMoyen : Colors.blueGrey;
    }
  }

  @override
  State<TogoMapWidget> createState() => _TogoMapWidgetState();
}

class _TogoMapWidgetState extends State<TogoMapWidget>
    with TickerProviderStateMixin {
  late String _activeCode;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;

  // Cache du Path SVG pour éviter de recalculer le parsing à chaque frame
  static Path? _cachedRawTogoPath;

  static Path _getTogoPath() {
    if (_cachedRawTogoPath != null) return _cachedRawTogoPath!;
    final p = Path();
    writeSvgPathDataToPath(togoSvgPathData, _SvgToPathProxy(p));
    _cachedRawTogoPath = p;
    return p;
  }

  @override
  void initState() {
    super.initState();
    _activeCode = widget.codeRegionSelectionnee ??
        (widget.regions.isNotEmpty ? widget.regions.last.code : 'maritime');

    // Animation 1 : Pulsation / radar de la région active
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    // Animation 2 : Flottement subtil des pastilles météo sur la carte
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didUpdateWidget(covariant TogoMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.codeRegionSelectionnee != null &&
        widget.codeRegionSelectionnee != _activeCode) {
      setState(() => _activeCode = widget.codeRegionSelectionnee!);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  RegionMeteo get _regionActive {
    return widget.regions.firstWhere(
      (r) => r.code == _activeCode,
      orElse: () => widget.regions.isNotEmpty
          ? widget.regions.last
          : BulletinMeteo.regionsParDefaut.last,
    );
  }

  void _selectionnerCode(String code) {
    setState(() => _activeCode = code);
    final r = widget.regions.firstWhere(
      (item) => item.code == code,
      orElse: () => BulletinMeteo.regionsParDefaut.first,
    );
    widget.onRegionSelected(r);
  }

  IconData _getIconData(String icone) => TogoMapWidget.getIconData(icone);
  Color _getIconColor(String icone, bool isDark) => TogoMapWidget.getIconColor(icone, isDark);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceSombre : Colors.white;
    final borderColor = isDark ? AppColors.bordureSombre : const Color(0xFFE8E8E8);
    final region = _regionActive;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec badge interactif
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.map_rounded,
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
                      'TOGO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isDark ? AppColors.texteSombreFort : AppColors.texteFort,
                      ),
                    ),
                    Text(
                      'Touchez la carte ou une région pour voir ses détails',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Zone centrale : Carte SVG animée à gauche + Liste des 5 régions à droite
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte SVG interactive et animée du Togo
              GestureDetector(
                onTapUp: (details) {
                  // Détection de la région touchée en fonction du ratio Y
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final relativeY = details.localPosition.dy / 300.0;
                  if (relativeY < 0.20) {
                    _selectionnerCode('savanes');
                  } else if (relativeY < 0.38) {
                    _selectionnerCode('kara');
                  } else if (relativeY < 0.58) {
                    _selectionnerCode('centrale');
                  } else if (relativeY < 0.80) {
                    _selectionnerCode('plateaux');
                  } else {
                    _selectionnerCode('maritime');
                  }
                },
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseController, _floatController]),
                  builder: (context, _) {
                    return SizedBox(
                      width: 110,
                      height: 300,
                      child: CustomPaint(
                        painter: _RealTogoSvgPainter(
                          rawPath: _getTogoPath(),
                          activeCode: _activeCode,
                          pulseValue: _pulseAnim.value,
                          floatOffset: _floatAnim.value,
                          isDark: isDark,
                          regions: widget.regions,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Sélecteur des 5 régions géographiques (du Nord au Sud)
              Expanded(
                child: Column(
                  children: widget.regions.map((r) {
                    final isSelected = r.code == _activeCode;
                    final iconColor = _getIconColor(r.icone, isDark);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: InkWell(
                        onTap: () => _selectionnerCode(r.code),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.vertClair.withValues(alpha: 0.18)
                                    : AppColors.vertPrimaire.withValues(alpha: 0.12))
                                : (isDark
                                    ? AppColors.surfaceSombreLegere.withValues(alpha: 0.5)
                                    : const Color(0xFFF8FAF8)),
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
                              Icon(_getIconData(r.icone), size: 19, color: iconColor),
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

          // ── Fiche détaillée et animée de la région sélectionnée ──
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Container(
              key: ValueKey<String>(region.code),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceSombreLegere : const Color(0xFFF3F8F4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.vertClair.withValues(alpha: 0.35)
                      : AppColors.vertPrimaire.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getIconColor(region.icone, isDark).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconData(region.icone),
                          color: _getIconColor(region.icone, isDark),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Région ${region.nom}',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.texteSombreFort : AppColors.vertFonce,
                              ),
                            ),
                            Text(
                              'Chef-lieu : ${region.chefLieu}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                              .withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${region.tempMin.toInt()}°C – ${region.tempMax.toInt()}°C',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    region.condition,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.texteSombreFort : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter effectuant le rendu vectoriel authentique du SVG du Togo
/// avec séparation en 5 régions administratives, animations de pulsation,
/// lueur, vagues côtières et pastilles flottantes.
class _RealTogoSvgPainter extends CustomPainter {
  final Path rawPath;
  final String activeCode;
  final double pulseValue;
  final double floatOffset;
  final bool isDark;
  final List<RegionMeteo> regions;

  _RealTogoSvgPainter({
    required this.rawPath,
    required this.activeCode,
    required this.pulseValue,
    required this.floatOffset,
    required this.isDark,
    required this.regions,
  });

  // Limites exactes du contour SVG de togo.svg :
  // X: [31.00, 70.00] (largeur = 39.00)
  // Y: [0.20, 98.80] (hauteur = 98.60)
  static const double _svgMinX = 31.00;
  static const double _svgMinY = 0.20;
  static const double _svgWidth = 39.00;
  static const double _svgHeight = 98.60;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // 1. Calcul de la matrice d'échelle pour adapter la géométrie vectorielle
    final scale = math.min(size.width / _svgWidth, size.height / _svgHeight) * 0.95;
    final offsetX = (size.width - (_svgWidth * scale)) / 2 - (_svgMinX * scale);
    final offsetY = (size.height - (_svgHeight * scale)) / 2 - (_svgMinY * scale);

    final transformMatrix = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, offsetX)
      ..setEntry(1, 3, offsetY);

    final togoPath = rawPath.transform(transformMatrix.storage);
    final bounds = togoPath.getBounds();

    // 2. Ombre portée réaliste du pays
    canvas.drawShadow(
      togoPath,
      isDark ? Colors.black.withValues(alpha: 0.6) : AppColors.vertFonce.withValues(alpha: 0.25),
      8.0,
      true,
    );

    // 3. Découpage aux frontières réelles du Togo
    canvas.save();
    canvas.clipPath(togoPath);

    // Fond par défaut de l'ensemble du pays
    final defaultFill = isDark ? const Color(0xFF1E232E) : const Color(0xFFE2EBE3);
    canvas.drawRect(
      bounds,
      Paint()..color = defaultFill,
    );

    // 4. Délimitation géographique des 5 régions le long de l'axe Nord-Sud
    // Découpage Y proportionnel officiel :
    // - Savanes  : 0% à 20%
    // - Kara     : 20% à 38%
    // - Centrale : 38% à 58%
    // - Plateaux : 58% à 80%
    // - Maritime : 80% à 100%
    final h = bounds.height;
    final y0 = bounds.top;
    final ySavanesEnd = y0 + h * 0.20;
    final yKaraEnd = y0 + h * 0.38;
    final yCentraleEnd = y0 + h * 0.58;
    final yPlateauxEnd = y0 + h * 0.80;
    final yMaritimeEnd = y0 + h;

    // Dessine et colore chaque région
    _drawRegionBand(canvas, bounds, y0, ySavanesEnd, 'savanes');
    _drawRegionBand(canvas, bounds, ySavanesEnd, yKaraEnd, 'kara');
    _drawRegionBand(canvas, bounds, yKaraEnd, yCentraleEnd, 'centrale');
    _drawRegionBand(canvas, bounds, yCentraleEnd, yPlateauxEnd, 'plateaux');
    _drawRegionBand(canvas, bounds, yPlateauxEnd, yMaritimeEnd, 'maritime');

    // Lignes de séparation administratives
    final linePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final y in [ySavanesEnd, yKaraEnd, yCentraleEnd, yPlateauxEnd]) {
      canvas.drawLine(Offset(bounds.left - 20, y), Offset(bounds.right + 20, y), linePaint);
    }

    // Vagues animées dans le Golfe de Guinée au Sud (Lomé)
    final waveY = yMaritimeEnd - 2;
    final wavePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final wavePath = Path();
    for (double x = bounds.left; x <= bounds.right; x += 10) {
      final y = waveY + math.sin((x / 8) + (pulseValue * math.pi * 2)) * 1.5;
      if (x == bounds.left) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }
    canvas.drawPath(wavePath, wavePaint);

    canvas.restore(); // Fin du clip

    // 5. Contour extérieur officiel SVG de haute précision
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF4C5870) : AppColors.vertFonce.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(togoPath, borderPaint);

    // 6. Pastilles météo animées flottantes sur chaque région
    RegionMeteo getRegion(String code) {
      return regions.firstWhere(
        (r) => r.code == code,
        orElse: () => BulletinMeteo.regionsParDefaut.firstWhere((r) => r.code == code),
      );
    }

    final rSavanes = getRegion('savanes');
    final rKara = getRegion('kara');
    final rCentrale = getRegion('centrale');
    final rPlateaux = getRegion('plateaux');
    final rMaritime = getRegion('maritime');

    _drawFloatingMarker(
      canvas,
      bounds.left + bounds.width * 0.48,
      y0 + (h * 0.10) + (activeCode == 'savanes' ? floatOffset : 0),
      'savanes',
      TogoMapWidget.getIconData(rSavanes.icone),
      TogoMapWidget.getIconColor(rSavanes.icone, isDark),
      rSavanes.tempMax,
    );

    _drawFloatingMarker(
      canvas,
      bounds.left + bounds.width * 0.52,
      y0 + (h * 0.29) + (activeCode == 'kara' ? floatOffset : 0),
      'kara',
      TogoMapWidget.getIconData(rKara.icone),
      TogoMapWidget.getIconColor(rKara.icone, isDark),
      rKara.tempMax,
    );

    _drawFloatingMarker(
      canvas,
      bounds.left + bounds.width * 0.49,
      y0 + (h * 0.48) + (activeCode == 'centrale' ? floatOffset : 0),
      'centrale',
      TogoMapWidget.getIconData(rCentrale.icone),
      TogoMapWidget.getIconColor(rCentrale.icone, isDark),
      rCentrale.tempMax,
    );

    _drawFloatingMarker(
      canvas,
      bounds.left + bounds.width * 0.54,
      y0 + (h * 0.69) + (activeCode == 'plateaux' ? floatOffset : 0),
      'plateaux',
      TogoMapWidget.getIconData(rPlateaux.icone),
      TogoMapWidget.getIconColor(rPlateaux.icone, isDark),
      rPlateaux.tempMax,
    );

    _drawFloatingMarker(
      canvas,
      bounds.left + bounds.width * 0.58,
      y0 + (h * 0.90) + (activeCode == 'maritime' ? floatOffset : 0),
      'maritime',
      TogoMapWidget.getIconData(rMaritime.icone),
      TogoMapWidget.getIconColor(rMaritime.icone, isDark),
      rMaritime.tempMax,
    );

    canvas.restore();
  }

  void _drawRegionBand(
    Canvas canvas,
    Rect bounds,
    double top,
    double bottom,
    String code,
  ) {
    final isSelected = activeCode == code;
    final regionRect = Rect.fromLTRB(bounds.left - 20, top, bounds.right + 20, bottom);

    if (isSelected) {
      // Dégradé vert animé avec pulsation lumineuse
      final activeAlpha = 0.55 + (pulseValue * 0.25);
      final activeColor = (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
          .withValues(alpha: activeAlpha);
      final activePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            activeColor,
            (isDark ? const Color(0xFF238645) : const Color(0xFF1B5E20))
                .withValues(alpha: activeAlpha),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(regionRect);

      canvas.drawRect(regionRect, activePaint);
    } else {
      // Teinte douce discrète
      final subtleColor = isDark
          ? const Color(0xFF1A1F29)
          : const Color(0xFFEDF4EE);
      canvas.drawRect(regionRect, Paint()..color = subtleColor);
    }
  }

  void _drawFloatingMarker(
    Canvas canvas,
    double cx,
    double cy,
    String code,
    IconData iconData,
    Color iconColor,
    double tempMax,
  ) {
    final isSelected = activeCode == code;
    final pillWidth = isSelected ? 52.0 : 44.0;
    final pillHeight = isSelected ? 24.0 : 20.0;
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: pillWidth,
      height: pillHeight,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(pillHeight / 2));

    // Cercle pulsation radar si sélectionné
    if (isSelected) {
      final pulseRRect = RRect.fromRectAndRadius(
        rect.inflate(4.0 + (pulseValue * 5.0)),
        Radius.circular((pillHeight / 2) + 4.0),
      );
      final radarPaint = Paint()
        ..color = (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
            .withValues(alpha: 0.35 * (1.0 - pulseValue))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(pulseRRect, radarPaint);
    }

    // Ombre de la pastille
    canvas.drawShadow(
      Path()..addRRect(rrect),
      Colors.black.withValues(alpha: isDark ? 0.45 : 0.2),
      isSelected ? 4.0 : 2.0,
      false,
    );

    // Fond de la pastille
    final markerPaint = Paint()
      ..color = isSelected
          ? (isDark ? const Color(0xFF1B3828) : const Color(0xFFE8F5E9))
          : (isDark ? const Color(0xFF222938) : Colors.white)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, markerPaint);

    // Bordure
    final borderPaint = Paint()
      ..color = isSelected
          ? (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
          : (isDark ? const Color(0xFF4C5870) : Colors.grey.shade300)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.8 : 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // Icône météo dynamique
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          inherit: false,
          color: iconColor,
          fontSize: isSelected ? 13.0 : 11.0,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Température dynamique
    final tempText = '${tempMax.round()}°';
    final textPainter = TextPainter(
      text: TextSpan(
        text: tempText,
        style: TextStyle(
          color: isSelected
              ? (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
              : (isDark ? Colors.white : Colors.black87),
          fontSize: isSelected ? 10.5 : 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final spacing = 3.0;
    final totalWidth = iconPainter.width + spacing + textPainter.width;
    final startX = cx - (totalWidth / 2);

    iconPainter.paint(
      canvas,
      Offset(startX, cy - (iconPainter.height / 2)),
    );

    textPainter.paint(
      canvas,
      Offset(startX + iconPainter.width + spacing, cy - (textPainter.height / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant _RealTogoSvgPainter oldDelegate) {
    return oldDelegate.activeCode != activeCode ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.floatOffset != floatOffset ||
        oldDelegate.isDark != isDark ||
        oldDelegate.regions != regions;
  }
}
