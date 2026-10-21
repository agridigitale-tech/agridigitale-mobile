import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/design/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../home/article_detail_screen.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});
  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  final _dio = ApiClient().dio;
  List<dynamic> _notifs = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final rep = await _dio.get('/notifications');
      setState(() {
        _notifs = rep.data as List;
        _chargement = false;
      });
      // Marquer comme lues après chargement réussi
      try {
        await _dio.post('/notifications/marquer-lues');
        if (mounted) context.read<NotificationProvider>().reset();
      } catch (_) {}
    } catch (_) {
      setState(() => _chargement = false);
    }
  }

  String _formaterDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yyyy \u00b7 HH:mm', 'fr_FR').format(d);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes notifications'),
        backgroundColor: AppColors.vertPrimaire,
        foregroundColor: Colors.white,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
          : _notifs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.grisIcone),
                      SizedBox(height: 12),
                      Text('Aucune notification', style: TextStyle(color: AppColors.grisTexte, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final n = _notifs[i];
                      final lu = n['lu'] == true;
                      final articleId = n['articleId'] as String?;
                      return GestureDetector(
                        onTap: articleId != null && articleId.isNotEmpty
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ArticleDetailScreen(articleId: articleId),
                                  ),
                                )
                            : null,
                        child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: lu ? Colors.white : AppColors.vertPrimaire.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: lu
                                ? Colors.grey.shade200
                                : AppColors.vertPrimaire.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: lu
                                    ? Colors.grey.shade100
                                    : AppColors.vertPrimaire.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: lu ? AppColors.grisIcone : AppColors.vertPrimaire,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n['titre'] ?? '',
                                          style: TextStyle(
                                            fontWeight: lu ? FontWeight.w500 : FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (!lu)
                                        Container(
                                          width: 8, height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.vertPrimaire,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n['message'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formaterDate(n['dateEnvoi'] ?? n['createdAt']),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
