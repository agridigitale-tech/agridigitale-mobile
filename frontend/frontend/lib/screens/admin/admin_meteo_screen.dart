import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/admin_service.dart';
import '../../core/design/app_colors.dart';

class AdminMeteoScreen extends StatefulWidget {
  const AdminMeteoScreen({super.key});
  @override
  State<AdminMeteoScreen> createState() => _AdminMeteoScreenState();
}

class _AdminMeteoScreenState extends State<AdminMeteoScreen> {
  final _service = AdminService();
  File? _image;
  bool _envoi = false;

  Future<void> _choisirImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  void _dialogSource() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Choisir une image',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppColors.vertPrimaire,
                  child: Icon(Icons.camera_alt, color: Colors.white)),
              title: const Text('Prendre une photo'),
              onTap: () { Navigator.pop(context); _choisirImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.photo_library, color: Colors.white)),
              title: const Text('Choisir depuis la galerie'),
              onTap: () { Navigator.pop(context); _choisirImage(ImageSource.gallery); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _publier() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une image'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _envoi = true);
    try {
      await _service.publierMeteoManuelle(cheminImage: _image!.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo météo publiée'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publier photo météo',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.vertPrimaire,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Zone image
            Expanded(
              child: GestureDetector(
                onTap: _dialogSource,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _image != null ? AppColors.vertPrimaire : Colors.grey[300]!,
                      width: _image != null ? 2 : 1,
                    ),
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_image!, fit: BoxFit.cover),
                              Positioned(
                                top: 10, right: 10,
                                child: GestureDetector(
                                  onTap: () => setState(() => _image = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                        color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12, right: 12,
                                child: GestureDetector(
                                  onTap: _dialogSource,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text('Changer', style: TextStyle(color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 14),
                            Text('Appuyez pour ajouter une photo météo',
                                style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                            const SizedBox(height: 6),
                            Text('Galerie ou appareil photo',
                                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Bouton publier
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _envoi ? null : _publier,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vertPrimaire,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _envoi
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_done_outlined, color: Colors.white),
                label: Text(
                  _envoi ? 'Publication...' : 'Publier la photo',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
