// Écran détail d'un article : affiche l'image sans rognage, la légende photo,
// la synthèse vocale (lecture audio), la traduction en anglais, le contenu HTML soigné,
// les réseaux sociaux, les commentaires et les articles similaires.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/article_service.dart';
import '../../services/favori_service.dart';
import '../../services/commentaire_service.dart';
import '../../models/article.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/auth_gate.dart';
import '../../widgets/karaoke_reader.dart';
import '../../core/design/app_colors.dart';
import '../../core/api_client.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;
  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _articleService = ArticleService();
  final _favoriService = FavoriService();
  final _commentaireService = CommentaireService();
  final _commentaireCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const String _domaineImages = 'https://agridigitale.net';
  final _progression = ValueNotifier<double>(0);

  late Future<Article> _future;
  late Future<List<Article>> _autresFuture;
  List<Commentaire> _commentaires = [];
  bool _chargementCommentaires = false;
  bool _envoi = false;
  bool _favoriTraite = false;
  bool _estFavori = false;

  // ── Synthèse vocale (Text-To-Speech) & Suivi Karaoké ──
  final FlutterTts _tts = FlutterTts();
  bool _ttsEnLecture = false;
  bool _ttsEnPause = false;
  double _ttsVitesse = 0.5;
  List<String> _morceauxAudio = [];
  int _indexMorceauAudio = 0;
  bool _audioArretDemande = false;
  Timer? _timerProgressionFallback;
  DateTime _dernierTickProgress = DateTime.now();
  Article? _articleCourant;

  final ValueNotifier<EtatLectureAudio> _etatLectureNotifier =
      ValueNotifier<EtatLectureAudio>(EtatLectureAudio.initial());

  // ── Mode Anglais / Traduction ──
  bool _modeAnglais = false;

  @override
  void initState() {
    super.initState();
    _future = _articleService.detail(widget.articleId);
    _autresFuture = _articleService.lister();
    _chargerCommentaires();
    _initTts();
    _scrollCtrl.addListener(_majProgression);
    _favoriService.estEnFavori(widget.articleId).then((v) {
      if (mounted) setState(() => _estFavori = v);
    });
  }

  void _majProgression() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    if (max <= 0) return;
    final v = (_scrollCtrl.position.pixels / max).clamp(0.0, 1.0);
    _progression.value = v;
  }

  Future<void> _initTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          ],
          IosTextToSpeechAudioMode.defaultMode,
        );
      }
      final dispo = await _tts.isLanguageAvailable('fr-FR');
      if (dispo == true) {
        await _tts.setLanguage('fr-FR');
      } else {
        await _tts.setLanguage('fr');
      }
      await _tts.setSpeechRate(_ttsVitesse);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setProgressHandler((String text, int start, int end, String word) {
        _surProgressionTts(text, start, end, word);
      });

      _tts.setErrorHandler((msg) {
        debugPrint('[TTS] Erreur TTS : $msg');
        _arreterLecture();
      });
    } catch (e) {
      debugPrint('[TTS] Initialisation ignorée : $e');
    }
  }

  @override
  void dispose() {
    _audioArretDemande = true;
    _annulerTimerFallback();
    _scrollCtrl.removeListener(_majProgression);
    _progression.dispose();
    _tts.stop();
    _etatLectureNotifier.dispose();
    _commentaireCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Nettoie les balises et entités HTML pour une prononciation naturelle
  String _nettoyerTextePourAudio(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&#8217;', "'")
        .replaceAll('&#039;', "'")
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', ' et ')
        .replaceAll('&eacute;', 'é')
        .replaceAll('&egrave;', 'è')
        .replaceAll('&agrave;', 'à')
        .replaceAll('&ccedil;', 'ç')
        .replaceAll('&ocirc;', 'ô')
        .replaceAll('&ecirc;', 'ê')
        .replaceAll('&icirc;', 'î')
        .replaceAll('{{BASE_URL}}', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Découpe le texte en blocs de ~350 caractères pour respecter les limites
  // de synthèse vocale, cadencer les phrases et afficher le texte en karaoké.
  List<String> _decouperEnMorceaux(String texte) {
    final phrases = RegExp(r'[^.!?\n]+[.!?\n]+')
        .allMatches(texte)
        .map((m) => m.group(0)!.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (phrases.isEmpty && texte.trim().isNotEmpty) {
      return [texte.trim()];
    }
    final List<String> morceaux = [];
    var buffer = StringBuffer();
    for (final p in phrases) {
      if (buffer.length + p.length > 350 && buffer.isNotEmpty) {
        morceaux.add(buffer.toString().trim());
        buffer = StringBuffer();
      }
      buffer.write('$p ');
    }
    if (buffer.isNotEmpty) {
      morceaux.add(buffer.toString().trim());
    }
    return morceaux.where((s) => s.isNotEmpty).toList();
  }

  // ── Synchronisation du mot en temps réel (Karaoké) ──
  void _surProgressionTts(String text, int start, int end, String word) {
    _dernierTickProgress = DateTime.now();
    final mots = _etatLectureNotifier.value.mots;
    if (mots.isEmpty) return;

    int indexTrouve = -1;
    // 1. Recherche par position start/end absolue dans le morceau
    for (int i = 0; i < mots.length; i++) {
      final m = mots[i];
      if ((start >= m.debut && start < m.fin) ||
          (end > m.debut && end <= m.fin) ||
          (m.debut >= start && m.fin <= end)) {
        indexTrouve = i;
        break;
      }
    }

    // 2. Repli par correspondance textuelle si les index ne concordent pas
    if (indexTrouve == -1 && word.trim().isNotEmpty) {
      final motPropre = word.trim().toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      final debutRecherche = _etatLectureNotifier.value.indexMotActuel.clamp(0, mots.length - 1);
      for (int i = debutRecherche; i < mots.length; i++) {
        final mPropre = mots[i].mot.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        if (mPropre == motPropre) {
          indexTrouve = i;
          break;
        }
      }
    }

    if (indexTrouve != -1 && indexTrouve != _etatLectureNotifier.value.indexMotActuel) {
      _etatLectureNotifier.value = _etatLectureNotifier.value.copyWith(
        indexMotActuel: indexTrouve,
      );
    }
  }

  void _demarrerTimerProgressionFallback(List<MotLecture> mots) {
    _annulerTimerFallback();
    if (mots.isEmpty) return;
    _dernierTickProgress = DateTime.now();
    _timerProgressionFallback = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!_ttsEnLecture || _ttsEnPause) return;
      final diff = DateTime.now().difference(_dernierTickProgress).inMilliseconds;
      final dureeParMotMs = (380 / (_ttsVitesse / 0.5)).clamp(180, 800).round();
      if (diff > dureeParMotMs) {
        final idx = _etatLectureNotifier.value.indexMotActuel;
        if (idx < mots.length - 1) {
          _dernierTickProgress = DateTime.now();
          _etatLectureNotifier.value = _etatLectureNotifier.value.copyWith(
            indexMotActuel: idx + 1,
          );
        }
      }
    });
  }

  void _annulerTimerFallback() {
    _timerProgressionFallback?.cancel();
    _timerProgressionFallback = null;
  }

  // ── Gestion de la lecture vocale ──
  Future<void> _lireArticle(Article article) async {
    _articleCourant = article;

    // Si en cours de lecture → Mettre en pause
    if (_ttsEnLecture) {
      _audioArretDemande = true;
      _annulerTimerFallback();
      await _tts.stop();
      if (mounted) {
        setState(() {
          _ttsEnLecture = false;
          _ttsEnPause = true;
        });
      }
      _etatLectureNotifier.value = _etatLectureNotifier.value.copyWith(
        estEnLecture: false,
        estEnPause: true,
      );
      return;
    }

    // Si en pause → Reprendre
    if (_ttsEnPause && _morceauxAudio.isNotEmpty) {
      _audioArretDemande = false;
      if (mounted) {
        setState(() {
          _ttsEnLecture = true;
          _ttsEnPause = false;
        });
      }
      _etatLectureNotifier.value = _etatLectureNotifier.value.copyWith(
        estEnLecture: true,
        estEnPause: false,
      );
      _jouerMorceauxAudio();
      return;
    }

    // Nouveau démarrage de lecture
    final titre = _nettoyerTextePourAudio(article.titre);
    final resume = _nettoyerTextePourAudio(article.resume);
    final corps = _nettoyerTextePourAudio(article.contenu);
    final texteComplet = '$titre. $resume. $corps';

    _morceauxAudio = _decouperEnMorceaux(texteComplet);
    _indexMorceauAudio = 0;
    _audioArretDemande = false;

    if (_morceauxAudio.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun texte à lire disponible.')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _ttsEnLecture = true;
        _ttsEnPause = false;
      });
    }

    _jouerMorceauxAudio();
  }

  Future<void> _jouerMorceauxAudio() async {
    try {
      await _tts.setLanguage(_modeAnglais ? 'en-US' : 'fr-FR');
      await _tts.setSpeechRate(_ttsVitesse);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      while (_indexMorceauAudio < _morceauxAudio.length && !_audioArretDemande) {
        final morceau = _morceauxAudio[_indexMorceauAudio];
        final mots = MotLecture.extraireMots(morceau);

        _etatLectureNotifier.value = EtatLectureAudio(
          estActif: true,
          estEnLecture: true,
          estEnPause: false,
          vitesse: _ttsVitesse,
          indexMorceau: _indexMorceauAudio,
          totalMorceaux: _morceauxAudio.length,
          morceauTexte: morceau,
          mots: mots,
          indexMotActuel: 0,
          titreArticle: _articleCourant?.titre ?? '',
          estReduit: _etatLectureNotifier.value.estReduit,
        );

        // Auto-défilement progressif du corps de l'article pour suivre la voix
        if (_scrollCtrl.hasClients && _morceauxAudio.isNotEmpty) {
          final ratio = _indexMorceauAudio / _morceauxAudio.length;
          final maxScroll = _scrollCtrl.position.maxScrollExtent;
          final target = (ratio * maxScroll * 0.85).clamp(0.0, maxScroll);
          _scrollCtrl.animateTo(
            target,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
          );
        }

        _demarrerTimerProgressionFallback(mots);
        await _tts.speak(morceau);
        _annulerTimerFallback();

        if (_audioArretDemande) break;
        _indexMorceauAudio++;
      }

      if (!_audioArretDemande && _indexMorceauAudio >= _morceauxAudio.length) {
        _arreterLecture();
      }
    } catch (e) {
      debugPrint('[TTS] Erreur : $e');
      _arreterLecture();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de lecture audio : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Sauter directement à un mot précis dans la phrase
  Future<void> _sauterVersMot(int indexMot) async {
    if (_morceauxAudio.isEmpty || _indexMorceauAudio >= _morceauxAudio.length) return;
    final mots = _etatLectureNotifier.value.mots;
    if (indexMot < 0 || indexMot >= mots.length) return;

    _audioArretDemande = true;
    _annulerTimerFallback();
    await _tts.stop();

    final morceau = _morceauxAudio[_indexMorceauAudio];
    final debutMot = mots[indexMot].debut;
    final textePartiel = morceau.substring(debutMot);

    _etatLectureNotifier.value = _etatLectureNotifier.value.copyWith(
      estActif: true,
      estEnLecture: true,
      estEnPause: false,
      indexMotActuel: indexMot,
    );

    if (mounted) {
      setState(() {
        _ttsEnLecture = true;
        _ttsEnPause = false;
      });
    }

    _audioArretDemande = false;
    _demarrerTimerProgressionFallback(mots);
    try {
      await _tts.speak(textePartiel);
      _annulerTimerFallback();
      if (!_audioArretDemande) {
        _indexMorceauAudio++;
        _jouerMorceauxAudio();
      }
    } catch (_) {
      _annulerTimerFallback();
    }
  }

  Future<void> _morceauPrecedent() async {
    if (_indexMorceauAudio <= 0) return;
    _audioArretDemande = true;
    _annulerTimerFallback();
    await _tts.stop();
    _indexMorceauAudio--;
    _audioArretDemande = false;
    if (mounted) {
      setState(() {
        _ttsEnLecture = true;
        _ttsEnPause = false;
      });
    }
    _jouerMorceauxAudio();
  }

  Future<void> _morceauSuivant() async {
    if (_indexMorceauAudio >= _morceauxAudio.length - 1) return;
    _audioArretDemande = true;
    _annulerTimerFallback();
    await _tts.stop();
    _indexMorceauAudio++;
    _audioArretDemande = false;
    if (mounted) {
      setState(() {
        _ttsEnLecture = true;
        _ttsEnPause = false;
      });
    }
    _jouerMorceauxAudio();
  }

  Future<void> _arreterLecture() async {
    _audioArretDemande = true;
    _annulerTimerFallback();
    _indexMorceauAudio = 0;
    _morceauxAudio.clear();
    await _tts.stop();
    _etatLectureNotifier.value = EtatLectureAudio.initial();
    if (mounted) {
      setState(() {
        _ttsEnLecture = false;
        _ttsEnPause = false;
      });
    }
  }

  void _changerVitesseTts() {
    double nouvelleVitesse;
    if (_ttsVitesse == 0.5) {
      nouvelleVitesse = 0.65; // ~1.25x
    } else if (_ttsVitesse == 0.65) {
      nouvelleVitesse = 0.8;  // ~1.5x
    } else {
      nouvelleVitesse = 0.5;  // 1.0x normal
    }
    setState(() => _ttsVitesse = nouvelleVitesse);
    _tts.setSpeechRate(nouvelleVitesse);
    _etatLectureNotifier.value = _etatLectureNotifier.value.copyWith(vitesse: nouvelleVitesse);
  }

  void _ouvrirPrompteurPleinEcran(Article article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PrompteurPleinEcranSheet(
        notifier: _etatLectureNotifier,
        onLectureToggle: () => _lireArticle(article),
        onPrecedent: _morceauPrecedent,
        onSuivant: _morceauSuivant,
        onChangerVitesse: _changerVitesseTts,
        onArreter: () {
          Navigator.pop(ctx);
          _arreterLecture();
        },
        onSauterVersMot: _sauterVersMot,
      ),
    );
  }

  void _basculerReductionLecteur() {
    final actuel = _etatLectureNotifier.value.estReduit;
    _etatLectureNotifier.value = _etatLectureNotifier.value.copyWith(estReduit: !actuel);
  }

  // ── Gestion Commentaires ──
  Future<void> _chargerCommentaires() async {
    setState(() => _chargementCommentaires = true);
    try {
      final liste = await _commentaireService.lister(widget.articleId);
      if (mounted) setState(() => _commentaires = liste);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _chargementCommentaires = false);
    }
  }

  Future<void> _envoyerCommentaire() async {
    final texte = _commentaireCtrl.text.trim();
    if (texte.length < 2) return;
    final connecte = await exigerConnexion(context, motif: 'laisser un commentaire');
    if (!connecte) return;
    setState(() => _envoi = true);
    try {
      final c = await _commentaireService.ajouter(widget.articleId, texte);
      _commentaireCtrl.clear();
      if (mounted) {
        setState(() => _commentaires.insert(0, c));
        FocusScope.of(context).unfocus();
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

  Future<void> _supprimerCommentaire(Commentaire c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous supprimer ce commentaire ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _commentaireService.supprimer(widget.articleId, c.id);
      if (mounted) setState(() => _commentaires.remove(c));
    } catch (_) {}
  }

  // ── Partage ──
  void _partagerArticle(Article article) {
    final lien = article.lienSource.isNotEmpty
        ? article.lienSource
        : 'https://agridigitale.net/article/${article.id}';
    final texte = '${article.titre}\n$lien';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Partager via',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _boutonPartage(
                  icone: FontAwesomeIcons.whatsapp,
                  label: 'WhatsApp',
                  couleur: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse('https://wa.me/?text=${Uri.encodeComponent(texte)}'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                _boutonPartage(
                  icone: FontAwesomeIcons.facebookF,
                  label: 'Facebook',
                  couleur: const Color(0xFF1877F2),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(lien)}'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                _boutonPartage(
                  icone: FontAwesomeIcons.xTwitter,
                  label: 'X',
                  couleur: Colors.black,
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse('https://twitter.com/intent/tweet?text=${Uri.encodeComponent(texte)}'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                _boutonPartage(
                  icone: Icons.link,
                  label: 'Copier lien',
                  couleur: Colors.grey.shade700,
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: lien));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lien copié !')),
                    );
                  },
                ),
                _boutonPartage(
                  icone: Icons.share,
                  label: 'Autres',
                  couleur: AppColors.vertPrimaire,
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(texte, subject: article.titre);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _boutonPartage({
    required dynamic icone,
    required String label,
    required Color couleur,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: couleur.withValues(alpha: 0.12),
            child: icone is IconData
                ? Icon(icone, color: couleur, size: 22)
                : FaIcon(icone, color: couleur, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Future<void> _basculerFavori(Article article) async {
    setState(() => _favoriTraite = true);
    try {
      if (_estFavori) {
        await _favoriService.retirer(article.id);
        if (mounted) {
          setState(() => _estFavori = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Retiré des favoris'), duration: Duration(seconds: 1)),
          );
        }
      } else {
        await _favoriService.ajouter(article);
        if (mounted) {
          setState(() => _estFavori = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ajouté aux favoris'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      if (mounted && e.toString().contains('409')) {
        setState(() => _estFavori = true);
      }
    } finally {
      if (mounted) setState(() => _favoriTraite = false);
    }
  }

  String _formaterDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy · HH:mm', 'fr_FR').format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _tempsRelatif(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return '${date.day}/${date.month}/${date.year}';
  }

  // Sur le web, les images agridigitale.net n'exposent pas d'en-tête CORS :
  // on passe donc par le proxy backend. Sur mobile, l'accès direct fonctionne.
  String _proxyImage(String url) {
    if (!kIsWeb) return url;
    if (!url.startsWith('https://agridigitale.net') &&
        !url.startsWith('http://agridigitale.net') &&
        !url.startsWith('https://agridigitale.com') &&
        !url.startsWith('http://agridigitale.com')) {
      return url;
    }
    return '${ApiClient.baseUrl}/proxy-image?url=${Uri.encodeComponent(url)}';
  }

  // Convertit une URL d'image relative (/ck/xxx.jpg) ou un marqueur en URL absolue
  String _urlAbsolue(String url) {
    final u = url.trim();
    if (u.isEmpty) return url;
    if (RegExp(r'^(data:|blob:|mailto:|tel:|#)', caseSensitive: false).hasMatch(u)) {
      return url;
    }
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(u)) {
      return _proxyImage(
        u.replaceAll(
                RegExp(r'agridigitale\.com', caseSensitive: false), 'agridigitale.net')
            .replaceAllMapped(
                RegExp(r'^(https?://[^/]+)/ck/', caseSensitive: false),
                (m) => '${m.group(1)}/storage/ck/'),
      );
    }
    if (u.startsWith('//')) return _proxyImage('https:$u');
    return _proxyImage(
      '$_domaineImages${u.startsWith('/') ? u : '/$u'}'.replaceAllMapped(
          RegExp(r'^(https?://[^/]+)/ck/', caseSensitive: false),
          (m) => '${m.group(1)}/storage/ck/'),
    );
  }

  // Normalise une valeur srcset ("url1 1x, url2 2x") en absolutisant chaque URL
  String _normaliserSrcset(String valeur) => valeur.split(',').map((partie) {
        final bits = partie.trim().split(RegExp(r'\s+'));
        if (bits.isEmpty || bits[0].isEmpty) return partie.trim();
        bits[0] = _urlAbsolue(bits[0]);
        return bits.join(' ');
      }).join(', ');

  // Filtre de réécriture des balises <img> :
  //  - {{BASE_URL}} et agridigitale.com → agridigitale.net
  //  - /ck/ → /storage/ck/
  //  - src / data-src / srcset relatifs → URL absolues
  //  - promeut data-src en src (lazy-loading) quand src est vide
  String _normaliserImagesContenu(String html) {
    if (html.isEmpty) return html;
    var resultat = html
        .replaceAll(RegExp(r'\{\{BASE_URL\}\}', caseSensitive: false), _domaineImages)
        .replaceAll(RegExp(r'agridigitale\.com', caseSensitive: false), 'agridigitale.net');

    resultat = resultat.replaceAllMapped(
      RegExp(r'<img\b[^>]*>', caseSensitive: false),
      (tagMatch) {
        var tag = tagMatch.group(0)!;

        final dataSrc = RegExp(r'''\sdata-src\s*=\s*(["'])([\s\S]*?)\1''',
                caseSensitive: false)
            .firstMatch(tag);
        final srcMatch = RegExp(r'''\ssrc\s*=\s*(["'])([\s\S]*?)\1''',
                caseSensitive: false)
            .firstMatch(tag);
        final srcVide = srcMatch == null || srcMatch.group(2)!.trim().isEmpty;

        if (dataSrc != null && srcVide) {
          final absolue = _urlAbsolue(dataSrc.group(2)!);
          if (srcMatch != null) {
            tag = tag.replaceFirst(
                RegExp(r'''\ssrc\s*=\s*(["'])[\s\S]*?\1''', caseSensitive: false),
                ' src="$absolue"');
          } else {
            tag = tag.replaceFirst('<img', '<img src="$absolue"');
          }
        }

        tag = tag.replaceAllMapped(
          RegExp(r'''(\ssrc\s*=\s*)(["'])([\s\S]*?)\2''', caseSensitive: false),
          (m) => '${m[1]}${m[2]}${_urlAbsolue(m[3]!)}${m[2]}',
        );
        tag = tag.replaceAllMapped(
          RegExp(r'''(\sdata-src\s*=\s*)(["'])([\s\S]*?)\2''', caseSensitive: false),
          (m) => '${m[1]}${m[2]}${_urlAbsolue(m[3]!)}${m[2]}',
        );
        tag = tag.replaceAllMapped(
          RegExp(r'''(\ssrcset\s*=\s*)(["'])([\s\S]*?)\2''', caseSensitive: false),
          (m) => '${m[1]}${m[2]}${_normaliserSrcset(m[3]!)}${m[2]}',
        );

        return tag;
      },
    );
    return resultat;
  }

  // Nettoyage et normalisation du contenu HTML avec domaine officiel agridigitale.net
  String _getContenuHtml(Article article) {
    final texte = article.contenu.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (texte.isNotEmpty) {
      return _normaliserImagesContenu(article.contenu);
    }
    if (article.resume.isNotEmpty) return '<p>${article.resume}</p>';
    return '<p>Contenu en cours de chargement...</p>';
  }

  // Construit une figure HTML (<figure><img><figcaption>) :
  //  - classe "image-style-side" → image à gauche, légende à droite
  //  - sinon → image puis légende empilées (rendu bloc classique)
  Widget _construireFigure(ExtensionContext context) {
    final img = _extraireImageFigure(context);
    final legende = _extraireLegendeFigure(context);
    final src =
        (img.$1 != null && img.$1!.trim().isNotEmpty) ? _urlAbsolue(img.$1!) : null;
    final alt = img.$2 ?? '';

    if (src == null) {
      if (legende == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          legende,
          style: const TextStyle(
            fontSize: 12.5,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final imageWidget = GestureDetector(
      onTap: () => _afficherImagePleinEcran(src),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: src,
          fit: BoxFit.cover,
          width: double.infinity,
          memCacheWidth: 1080,
          placeholder: (_, __) => Container(
            height: 180,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.vertPrimaire),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 180,
            color: Colors.green[50],
            child: const Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 32),
            ),
          ),
        ),
      ),
    );

    final estSurLeCote = context.classes.contains('image-style-side');

    if (estSurLeCote) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 150, child: imageWidget),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                legende ?? alt,
                style: TextStyle(fontSize: 12.5, color: Colors.grey[700], height: 1.45),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          imageWidget,
          if (legende != null && legende.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              legende,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  (String?, String?) _extraireImageFigure(ExtensionContext context) {
    for (final el in context.elementChildren) {
      if (el.localName == 'img') {
        return (el.attributes['src'], el.attributes['alt']);
      }
      if (el.localName == 'a') {
        for (final sub in el.children) {
          if (sub.localName == 'img') {
            return (sub.attributes['src'], sub.attributes['alt']);
          }
        }
      }
    }
    return (null, null);
  }

  String? _extraireLegendeFigure(ExtensionContext context) {
    for (final el in context.elementChildren) {
      if (el.localName == 'figcaption') {
        final texte = el.text.trim();
        if (texte.isNotEmpty) return texte;
      }
    }
    return null;
  }

  // Affichage en plein écran avec zoom interactif
  void _afficherImagePleinEcran(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Photo', style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.8,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 60),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AGRIDIGITALE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.5),
          child: ValueListenableBuilder<double>(
            valueListenable: _progression,
            builder: (_, valeur, __) => LinearProgressIndicator(
              value: valeur,
              minHeight: 2.5,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation(AppColors.vertPrimaire),
            ),
          ),
        ),
        actions: [
          // Bouton Traduire EN / FR
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: Text(_modeAnglais ? '🇬🇧' : '🇫🇷', style: const TextStyle(fontSize: 18)),
            label: Text(
              _modeAnglais ? 'EN' : 'FR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _modeAnglais ? AppColors.vertPrimaire : Colors.grey[700],
              ),
            ),
            onPressed: () async {
              final nouvelEtat = !_modeAnglais;
              setState(() => _modeAnglais = nouvelEtat);
              _arreterLecture();
              context.read<LanguageProvider>().basculerLangue();

              if (nouvelEtat) {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final a = await _future;
                  if (mounted && a.lienSource.isNotEmpty) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Articles rédigés en français. Ouvrir la version anglaise via Google Traduction ?',
                          style: TextStyle(fontSize: 12.5),
                        ),
                        action: SnackBarAction(
                          label: 'Ouvrir',
                          textColor: Colors.amberAccent,
                          onPressed: () {
                            final url =
                                'https://translate.google.com/translate?sl=fr&tl=en&u=${Uri.encodeComponent(a.lienSource)}';
                            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          },
                        ),
                        duration: const Duration(seconds: 6),
                      ),
                    );
                  }
                } catch (_) {}
              }
            },
          ),
          // Bouton Favori
          IconButton(
            tooltip: 'Favoris',
            icon: _favoriTraite
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.vertPrimaire))
                : Icon(
                    _estFavori ? Icons.bookmark : Icons.bookmark_border,
                    color: _estFavori ? AppColors.vertPrimaire : null,
                  ),
            onPressed: () {
              _future.then((a) => _basculerFavori(a));
            },
          ),
          // Bouton Partage
          IconButton(
            tooltip: 'Partager',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              _future.then((a) => _partagerArticle(a));
            },
          ),
        ],
      ),
      body: FutureBuilder<Article>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Impossible de charger l\'article'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _future = _articleService.detail(widget.articleId);
                      });
                    },
                    child: const Text('Réessayer', style: TextStyle(color: AppColors.vertPrimaire)),
                  ),
                ],
              ),
            );
          }
          final article = snapshot.data!;
          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollCtrl,
                slivers: [
                  _buildContenu(article),
                  _buildSectionCommentaires(auth),
                  _buildAutresArticles(),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 16,
                child: SafeArea(
                  child: BandeauKaraokeLecture(
                    notifier: _etatLectureNotifier,
                    onLectureToggle: () => _lireArticle(article),
                    onPrecedent: _morceauPrecedent,
                    onSuivant: _morceauSuivant,
                    onChangerVitesse: _changerVitesseTts,
                    onArreter: _arreterLecture,
                    onOuvrirPrompteur: () => _ouvrirPrompteurPleinEcran(article),
                    onSauterVersMot: _sauterVersMot,
                    onBasculerReduction: _basculerReductionLecteur,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Contenu éditorial de l'article (Design fidèle au site web)
  SliverToBoxAdapter _buildContenu(Article article) {
    final hasImage = article.image != null && article.image!.isNotEmpty;
    final legende = article.legendeImage.isNotEmpty
        ? article.legendeImage
        : 'Photo : © agridigitale.net';
    final auteur = article.auteur.isNotEmpty ? article.auteur : 'La Rédaction';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Badge Catégorie
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.vertPrimaire.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                article.categorie.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.vertPrimaire,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Grand Titre
            Text(
              article.titre,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            // 3. Auteur + Date + Vues
            Row(
              children: [
                Icon(Icons.person_outline, size: 15, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  auteur,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formaterDate(article.datePublication),
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                ),
                if (article.vues > 0) ...[
                  const SizedBox(width: 14),
                  Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${article.vues}',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Image Principale ENTIÈRE (Ratio 16:9 sans rognage, comme sur le site web)
            if (hasImage) ...[
              GestureDetector(
                onTap: () => _afficherImagePleinEcran(article.image!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: article.image!,
                          fit: BoxFit.cover,
                          memCacheWidth: 1080,
                          maxWidthDiskCache: 1200,
                          placeholder: (_, __) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.vertPrimaire,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.green[50],
                            child: const Icon(Icons.article, size: 60, color: Colors.green),
                          ),
                        ),
                        // Badge agrandir
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // 6. Légende & Crédit photo sous l'image
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 13, color: Colors.grey[600]),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      legende,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            const Divider(height: 20),

            // 7. Corps du Texte (HTML soigné)
            Html(
              data: _getContenuHtml(article),
              extensions: [
                TagExtension(
                  tagsToExtend: {'figure'},
                  builder: _construireFigure,
                ),
              ],
              onLinkTap: (url, attrs, element) {
                if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(16.5),
                  lineHeight: const LineHeight(1.75),
                  color: AppColors.texteFort,
                ),
                'p': Style(
                  textAlign: TextAlign.justify,
                  margin: Margins.only(bottom: 16),
                ),
                'h1': Style(fontSize: FontSize(22), fontWeight: FontWeight.bold, margin: Margins.only(bottom: 10, top: 16)),
                'h2': Style(fontSize: FontSize(20), fontWeight: FontWeight.bold, margin: Margins.only(bottom: 10, top: 14)),
                'h3': Style(fontSize: FontSize(18), fontWeight: FontWeight.bold, margin: Margins.only(bottom: 8, top: 12)),
                'blockquote': Style(
                  backgroundColor: const Color(0xFFF1F8E9),
                  padding: HtmlPaddings.symmetric(horizontal: 16, vertical: 12),
                  margin: Margins.symmetric(vertical: 14),
                  border: const Border(left: BorderSide(color: AppColors.vertPrimaire, width: 4)),
                  fontStyle: FontStyle.italic,
                ),
                'strong': Style(fontWeight: FontWeight.w700),
                'a': Style(color: AppColors.vertPrimaire, textDecoration: TextDecoration.underline),
                'img': Style(
                  margin: Margins.symmetric(vertical: 12),
                  width: Width(100, Unit.percent),
                ),
                'figure': Style(margin: Margins.symmetric(vertical: 12)),
                'figcaption': Style(
                  fontSize: FontSize(12),
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  textAlign: TextAlign.center,
                  margin: Margins.only(top: 4),
                ),
              },
            ),
            const SizedBox(height: 24),

            // Bouton source originale
            if (article.lienSource.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Lire sur www.agridigitale.net'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.vertPrimaire,
                    side: const BorderSide(color: AppColors.vertPrimaire),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => launchUrl(
                    Uri.parse(article.lienSource),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            _buildReseauxSociaux(),
          ],
        ),
      ),
    );
  }

  // Section "Suivez-nous"
  Widget _buildReseauxSociaux() {
    const reseaux = [
      (icone: FontAwesomeIcons.whatsapp,  couleur: Color(0xFF25D366), url: 'https://whatsapp.com/channel/0029VaWrkLsBqbr71Q6DvW2y'),
      (icone: FontAwesomeIcons.xTwitter,  couleur: Color(0xFF000000), url: 'https://x.com/agridigitale1'),
      (icone: FontAwesomeIcons.youtube,   couleur: Color(0xFFFF0000), url: 'https://youtube.com/@agridigitaletv'),
      (icone: FontAwesomeIcons.facebookF, couleur: Color(0xFF1877F2), url: 'https://facebook.com/agridigitale'),
      (icone: FontAwesomeIcons.instagram, couleur: Color(0xFFE1306C), url: 'https://instagram.com/agridigitale'),
      (icone: FontAwesomeIcons.linkedin,  couleur: Color(0xFF0A66C2), url: 'https://linkedin.com/company/agridigitale'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Text('Suivez-nous',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: reseaux.map((r) => GestureDetector(
                onTap: () => launchUrl(Uri.parse(r.url), mode: LaunchMode.externalApplication),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: r.couleur.withValues(alpha: 0.12),
                  child: FaIcon(r.icone, color: r.couleur, size: 14),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Section commentaires
  SliverToBoxAdapter _buildSectionCommentaires(AuthProvider auth) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.grey[50],
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.comment_outlined, color: AppColors.vertPrimaire),
                const SizedBox(width: 8),
                Text('Commentaires (${_commentaires.length})',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentaireCtrl,
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 1000,
                    enabled: auth.connecte,
                    onTap: !auth.connecte
                        ? () => exigerConnexion(context, motif: 'commenter')
                        : null,
                    decoration: InputDecoration(
                      hintText: auth.connecte
                          ? 'Écrire un commentaire...'
                          : 'Connectez-vous pour commenter',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _envoi ? null : _envoyerCommentaire,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vertPrimaire,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: _envoi
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_chargementCommentaires)
              const Center(child: CircularProgressIndicator(color: AppColors.vertPrimaire))
            else if (_commentaires.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Soyez le premier à commenter !',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _commentaires.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = _commentaires[i];
                  final estMien = auth.connecte && auth.nomUtilisateur == c.nomAuteur;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.vertPrimaire,
                      radius: 18,
                      child: Text(
                        c.nomAuteur.isNotEmpty ? c.nomAuteur[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(c.nomAuteur,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 8),
                        Text(_tempsRelatif(c.createdAt),
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(c.contenu,
                          style: const TextStyle(fontSize: 14, height: 1.4)),
                    ),
                    trailing: estMien
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () => _supprimerCommentaire(c),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Articles similaires
  Widget _buildAutresArticles() {
    return FutureBuilder<List<Article>>(
      future: _autresFuture,
      builder: (context, snap) {
        if (!snap.hasData) return const SliverToBoxAdapter(child: SizedBox.shrink());
        final autres = snap.data!.where((a) => a.id != widget.articleId).take(5).toList();
        if (autres.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.vertPrimaire,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'À lire aussi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.texteFort,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final a = autres[i - 1];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (a.image != null && a.image!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: a.image!,
                          width: 72, height: 56, fit: BoxFit.cover,
                          memCacheWidth: 200,
                          maxWidthDiskCache: 400,
                          errorWidget: (ctx, url, err) => Container(
                            width: 72, height: 56, color: Colors.green[50],
                            child: const Icon(Icons.article, color: Colors.green),
                          ),
                        )
                      : Container(
                          width: 72, height: 56, color: Colors.green[50],
                          child: const Icon(Icons.article, color: Colors.green),
                        ),
                ),
                title: Text(a.titre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${a.categorie.toUpperCase()} · ${_tempsRelatif(a.datePublication)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.vertPrimaire),
                ),
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: a.id)),
                ),
              );
            },
            childCount: autres.length + 1,
          ),
        );
      },
    );
  }
}
