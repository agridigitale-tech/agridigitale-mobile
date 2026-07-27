import 'package:dio/dio.dart' as dio_pkg;
import '../core/api_client.dart';

class AdminService {
  final _dio = ApiClient().dio;

  Future<Map<String, dynamic>> statistiques() async {
    final rep = await _dio.get('/admin/statistiques');
    return rep.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listerUtilisateurs() async {
    final rep = await _dio.get('/admin/utilisateurs');
    return rep.data as List<dynamic>;
  }

  Future<void> desactiverUtilisateur(String id) async {
    // validateStatus accepte tous les 2xx pour éviter les exceptions Dio sur réponse inattendue
    await _dio.put(
      '/admin/utilisateurs/$id/desactiver',
      options: dio_pkg.Options(validateStatus: (s) => s != null && s >= 200 && s < 300),
    );
  }

  Future<List<dynamic>> listerDemandes() async {
    final rep = await _dio.get('/demandes');
    return rep.data as List<dynamic>;
  }

  Future<void> traiterDemande(String id) async {
    await _dio.put('/demandes/$id/traiter');
  }

  Future<void> publierMeteoManuelle({required String cheminImage}) async {
    final formData = dio_pkg.FormData.fromMap({
      'photoMeteo': await dio_pkg.MultipartFile.fromFile(
        cheminImage,
        filename: cheminImage.split('/').last.split('\\').last,
      ),
    });
    await _dio.post('/meteo', data: formData);
  }

  Future<List<dynamic>> listerBannieres() async {
    // Endpoint admin : retourne toutes les bannières (actives + inactives)
    final rep = await _dio.get('/bannieres/admin');
    return rep.data as List<dynamic>;
  }

  Future<void> creerBanniere({required String image, required String lien, required int ordre, String? cheminFichier}) async {
    if (cheminFichier != null) {
      final formData = dio_pkg.FormData.fromMap({
        'lien': lien,
        'ordre': ordre.toString(),
        'actif': 'true',
        'image': await dio_pkg.MultipartFile.fromFile(
          cheminFichier,
          filename: cheminFichier.split('/').last.split('\\').last,
        ),
      });
      await _dio.post('/bannieres', data: formData);
    } else {
      await _dio.post('/bannieres', data: {'image': image, 'lien': lien, 'ordre': ordre, 'actif': true});
    }
  }

  Future<void> supprimerBanniere(String id) async {
    await _dio.delete('/bannieres/$id');
  }

  Future<Map<String, dynamic>> envoyerNotification({
    required String titre,
    required String message,
  }) async {
    final rep = await _dio.post('/notifications/manuelle', data: {
      'titre': titre,
      'message': message,
    });
    return rep.data as Map<String, dynamic>;
  }
}
