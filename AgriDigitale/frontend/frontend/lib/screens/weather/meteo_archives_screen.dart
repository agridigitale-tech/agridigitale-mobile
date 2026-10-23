import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/design/app_colors.dart';
import '../../core/db_helper.dart';
import 'models/bulletin_meteo.dart';

class MeteoArchivesScreen extends StatefulWidget {
  const MeteoArchivesScreen({super.key});
  @override
  State<MeteoArchivesScreen> createState() => _MeteoArchivesScreenState();
}

class _MeteoArchivesScreenState extends State<MeteoArchivesScreen> {
  final _db = DBHelper();
  List<BulletinMeteo> _bulletins = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final rows = await _db.getBulletinsSemestriels(limite: 180);
    final list = rows.map((r) => BulletinMeteo.fromDbRow(r)).toList();
    if (mounted) {
      setState(() {
        _bulletins = list;
        _chargement = false;
      });
    }
  }

  void _voirDetail(BuildContext context, BulletinMeteo b) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(b.date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceSombre : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bordureSombre : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bulletin archivé localement (sur votre appareil)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceSombreLegere : const Color(0xFFF6F8F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌅 Matinée', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 4),
                  Text(b.resumeMatin, style: const TextStyle(fontSize: 13)),
                  const Divider(height: 18),
                  const Text('🌤️ Après-midi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 4),
                  Text(b.resumeApresMidi, style: const TextStyle(fontSize: 13)),
                  const Divider(height: 18),
                  Text(
                    '🌡️ Températures : ${b.tempMin.toInt()}°C – ${b.tempMax.toInt()}°C',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (b.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Document officiel original :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: b.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppColors.vertPrimaire),
                    ),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Document non disponible en ligne'),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceSombre : Colors.white;
    final borderColor = isDark ? AppColors.bordureSombre : const Color(0xFFEEEEEE);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archives Semestrielles (Hors-ligne)'),
        elevation: 0,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
          : _bulletins.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 64,
                          color: isDark ? AppColors.texteSombreMoyen : AppColors.grisIcone,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun bulletin archivé pour l\'instant',
                          style: TextStyle(
                            color: isDark ? AppColors.texteSombreFort : AppColors.texteFort,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Les bulletins météo que vous consultez sont automatiquement sauvegardés sur votre téléphone jusqu\'à 6 mois.',
                          style: TextStyle(
                            color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _bulletins.length,
                  itemBuilder: (context, i) {
                    final b = _bulletins[i];
                    final dateStr = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(b.date);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.vertClair : AppColors.vertPrimaire)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.wb_sunny_outlined,
                            color: isDark ? AppColors.vertClair : AppColors.vertPrimaire,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          dateStr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: isDark ? AppColors.texteSombreFort : AppColors.texteFort,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${b.tempMin.toInt()}°C – ${b.tempMax.toInt()}°C • ${b.resumeMatin.length > 55 ? '${b.resumeMatin.substring(0, 55)}...' : b.resumeMatin}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.texteSombreMoyen : AppColors.grisTexte,
                            ),
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: isDark ? AppColors.texteSombreMoyen : AppColors.grisIcone,
                        ),
                        onTap: () => _voirDetail(context, b),
                      ),
                    );
                  },
                ),
    );
  }
}
