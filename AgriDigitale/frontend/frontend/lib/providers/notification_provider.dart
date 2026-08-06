import 'package:flutter/foundation.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import '../core/api_client.dart';

class NotificationProvider extends ChangeNotifier {
  int _nonLues = 0;
  int get nonLues => _nonLues;

  final _dio = ApiClient().dio;

  Future<void> rafraichir() async {
    try {
      final rep = await _dio.get('/notifications/non-lues');
      _nonLues = (rep.data['count'] as num?)?.toInt() ?? 0;
      _mettreAJourBadge();
      notifyListeners();
    } catch (_) {}
  }

  void incrementer() {
    _nonLues++;
    _mettreAJourBadge();
    notifyListeners();
  }

  void reset() {
    _nonLues = 0;
    AppBadgePlus.updateBadge(0);
    notifyListeners();
  }

  void _mettreAJourBadge() {
    if (_nonLues > 0) {
      AppBadgePlus.updateBadge(_nonLues);
    } else {
      AppBadgePlus.updateBadge(0);
    }
  }
}
