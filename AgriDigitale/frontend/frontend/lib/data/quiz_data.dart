// Catalogue de questions et niveaux pour le Quiz Agricole 100% hors-ligne.
// Adapté aux réalités agricoles du Togo et de l'Afrique de l'Ouest.

class QuestionQuiz {
  final int id;
  final String question;
  final List<String> options;
  final int bonneReponseIndex;
  final String explication;
  final String? astuceBonus;

  const QuestionQuiz({
    required this.id,
    required this.question,
    required this.options,
    required this.bonneReponseIndex,
    required this.explication,
    this.astuceBonus,
  });
}

class NiveauQuiz {
  final int id;
  final int mondeId;
  final String titre;
  final String description;
  final List<QuestionQuiz> questions;

  const NiveauQuiz({
    required this.id,
    required this.mondeId,
    required this.titre,
    required this.description,
    required this.questions,
  });
}

class MondeQuiz {
  final int id;
  final String nom;
  final String description;
  final String icone;
  final List<NiveauQuiz> niveaux;

  const MondeQuiz({
    required this.id,
    required this.nom,
    required this.description,
    required this.icone,
    required this.niveaux,
  });
}

class QuizData {
  static const List<MondeQuiz> mondes = [
    // ── MONDE 1 : Le Sol, le Compost & les Pépinières ──
    MondeQuiz(
      id: 1,
      nom: 'Sols & Pépinières',
      description: 'Fertilisation, compostage et démarrage réussi des plants',
      icone: '🌱',
      niveaux: [
        NiveauQuiz(
          id: 1,
          mondeId: 1,
          titre: 'Niveau 1 : Les secrets du compost',
          description: 'Transformer les déchets organiques en or noir',
          questions: [
            QuestionQuiz(
              id: 101,
              question: 'Quel ingrédient est indispensable pour accélérer la décomposition d\'un tas de compost ?',
              options: ['Le plastique', 'L\'humidité et l\'air', 'Le sel de cuisine', 'L\'eau de javel'],
              bonneReponseIndex: 1,
              explication: 'Un compost réussi a besoin d\'humidité constante et d\'oxygène apporté par un retournement régulier.',
              astuceBonus: 'Arrosez votre tas modérément comme une éponge pressée.',
            ),
            QuestionQuiz(
              id: 102,
              question: 'À quel moment de la journée est-il préférable d\'arroser les jeunes pépinières ?',
              options: ['À midi en plein soleil', 'Tôt le matin ou en fin d\'après-midi', 'À minuit', 'Uniquement quand il pleut'],
              bonneReponseIndex: 1,
              explication: 'Arroser à la fraîcheur évite l\'évaporation rapide de l\'eau et empêche les brûlures sur les jeunes feuilles.',
            ),
            QuestionQuiz(
              id: 103,
              question: 'Quel est l\'avantage principal du paillage (mulch) sur une planche maraîchère ?',
              options: ['Attirer les rongeurs', 'Conserver l\'humidité du sol et limiter les mauvaises herbes', 'Augmenter la température à 60°C', 'Empêcher la pluie de pénétrer'],
              bonneReponseIndex: 1,
              explication: 'La paille protège la vie microbienne du sol, freine l\'évaporation de 50% et étouffe les adventices.',
            ),
          ],
        ),
        NiveauQuiz(
          id: 2,
          mondeId: 1,
          titre: 'Niveau 2 : Réussir sa pépinière',
          description: 'Substrat, ombrage et repiquage des jeunes plants',
          questions: [
            QuestionQuiz(
              id: 104,
              question: 'Quelle est la profondeur idéale pour semer de petites graines comme la tomate ou le piment ?',
              options: ['À 10 cm sous terre', 'Environ 2 à 3 fois l\'épaisseur de la graine', 'Posée sur un caillou', 'À 20 cm sous terre'],
              bonneReponseIndex: 1,
              explication: 'Semer trop profondément épuise les réserves de la graine avant qu\'elle n\'atteigne la lumière du soleil.',
            ),
            QuestionQuiz(
              id: 105,
              question: 'Pourquoi pratique-t-on le sevrage de la pépinière quelques jours avant le repiquage ?',
              options: ['Pour tuer les plants', 'Pour endurcir les plants au soleil et au manque d\'eau', 'Pour faire tomber les feuilles', 'Pour attirer les papillons'],
              bonneReponseIndex: 1,
              explication: 'Réduire l\'ombrage et l\'arrosage 4 à 5 jours avant fortifie les plants contre le choc du repiquage au champ.',
            ),
            QuestionQuiz(
              id: 106,
              question: 'Quel type de terreau est optimal pour démarrer une pépinière ?',
              options: ['Du sable de mer salé', 'Un mélange terreau léger, sable fin et compost bien mûr', 'De l\'argile pure compacte', 'Des cailloux concassés'],
              bonneReponseIndex: 1,
              explication: 'Un substrat aéré et drainant facilite la pousse des racines fines sans risque de pourriture.',
            ),
          ],
        ),
        NiveauQuiz(
          id: 3,
          mondeId: 1,
          titre: 'Niveau 3 : La santé de la terre',
          description: 'Carence minérale, vers de terre et fertilité vivante',
          questions: [
            QuestionQuiz(
              id: 107,
              question: 'Que signifie la présence de nombreux vers de terre dans votre parcelle ?',
              options: ['Le sol est empoisonné', 'Le sol est vivant, aéré et riche en matière organique', 'Une invasion d\'insectes nuisibles', 'Le sol manque d\'eau'],
              bonneReponseIndex: 1,
              explication: 'Les vers de terre sont les meilleurs laboureurs naturels du sol, ils enrichissent la terre en minéraux assimilables.',
            ),
            QuestionQuiz(
              id: 108,
              question: 'Des feuilles jaunes avec des nervures vertes sur les jeunes pousses indiquent souvent :',
              options: ['Un excès d\'eau seulement', 'Une carence en fer (chlorose) ou en magnésium', 'Une attaque de criquets', 'Un sol trop riche'],
              bonneReponseIndex: 1,
              explication: 'La chlorose survient quand la plante n\'assimile pas le fer, souvent dans un sol trop calcaire ou mal drainé.',
            ),
            QuestionQuiz(
              id: 109,
              question: 'Pourquoi l\'arbre Faidherbia albida (Gao) est-il surnommé l\'arbre miracle des agriculteurs ?',
              options: ['Il donne des fruits sucrés en hiver', 'Il perd ses feuilles en saison des pluies et enrichit le sol en azote', 'Il fait fuir les oiseaux', 'Il produit du pétrole'],
              bonneReponseIndex: 1,
              explication: 'Faidherbia fertilise les cultures sans leur faire d\'ombre pendant la saison pluvieuse grâce à son feuillage inversé.',
            ),
          ],
        ),
      ],
    ),

    // ── MONDE 2 : Maraîchage (Tomate, Piment, Oignon) ──
    MondeQuiz(
      id: 2,
      nom: 'Maraîchage Pro',
      description: 'Tomates charnues, piments piquants et oignons sains',
      icone: '🍅',
      niveaux: [
        NiveauQuiz(
          id: 4,
          mondeId: 2,
          titre: 'Niveau 4 : Maître de la Tomate',
          description: 'Tuteurage, taille des gourmands et arrosage',
          questions: [
            QuestionQuiz(
              id: 201,
              question: 'Pourquoi évite-t-on de mouiller les feuilles de tomate lors de l\'arrosage ?',
              options: ['Pour économiser l\'eau', 'Pour éviter le développement du mildiou et des champignons', 'Pour que les feuilles ne tombent pas', 'Pour attirer les abeilles'],
              bonneReponseIndex: 1,
              explication: 'L\'humidité sur le feuillage de la tomate est la cause numéro 1 des maladies cryptogamiques comme le mildiou.',
            ),
            QuestionQuiz(
              id: 202,
              question: 'À quoi sert le tuteurage des plants de tomates ?',
              options: ['À faire de l\'ombre', 'À maintenir les fruits loin du sol humide et faciliter l\'aération', 'À empêcher les fleurs de s\'ouvrir', 'À attirer le vent'],
              bonneReponseIndex: 1,
              explication: 'Les tuteurs évitent le pourrissement des fruits au contact de la terre et simplifient la récolte.',
            ),
            QuestionQuiz(
              id: 203,
              question: 'La « pourriture apicale » (cul noir) de la tomate est principalement causée par :',
              options: ['Une carence en calcium souvent due à un arrosage irrégulier', 'Une piqûre de moustique', 'Un manque d\'engrais chimique', 'Un sol trop humide la nuit'],
              bonneReponseIndex: 0,
              explication: 'Un arrosage en dents de scie bloque l\'absorption du calcium, créant une tache noire au bout du fruit.',
            ),
          ],
        ),
        NiveauQuiz(
          id: 5,
          mondeId: 2,
          titre: 'Niveau 5 : L\'or du Piment',
          description: 'Variétés locales, piquant et protection naturelle',
          questions: [
            QuestionQuiz(
              id: 204,
              question: 'Quelle plante compagne repousse naturellement plusieurs ravageurs du piment lorsqu\'elle est plantée en bordure ?',
              options: ['L\'œillet d\'Inde (marigold)', 'Le manioc amer', 'Le bananier', 'Le chiendent'],
              bonneReponseIndex: 0,
              explication: 'Les racines et l\'odeur de l\'œillet d\'Inde sécrètent des nématicides naturels et repoussent pucerons et aleurodes.',
            ),
            QuestionQuiz(
              id: 205,
              question: 'Lorsque les feuilles de piment s\'enroulent comme une cuillère vers le haut, c\'est souvent le signe de :',
              options: ['Une soif intense', 'Pucerons ou acariens suceurs de sève sous les feuilles', 'Trop de soleil direct', 'Un champignon sous terre'],
              bonneReponseIndex: 1,
              explication: 'Les pucerons et acariens piquent la sève sous les jeunes feuilles, provoquant leur déformation en coupe.',
            ),
            QuestionQuiz(
              id: 206,
              question: 'Quel est le meilleur moment pour récolter les piments destinés au marché frais ?',
              options: ['Aux heures les plus chaudes de l\'après-midi', 'Le matin après la rosée quand les fruits sont fermes', 'Sous une forte pluie', 'La nuit sans lampe'],
              bonneReponseIndex: 1,
              explication: 'Récolter le matin garantit des fruits bien turgescents qui se conservent beaucoup plus longtemps en cagette.',
            ),
          ],
        ),
        NiveauQuiz(
          id: 6,
          mondeId: 2,
          titre: 'Niveau 6 : Oignons & Racines',
          description: 'Bulbification, séchage et stockage longue durée',
          questions: [
            QuestionQuiz(
              id: 207,
              question: 'Que faut-il faire sur l\'arrosage de l\'oignon environ 2 semaines avant la récolte ?',
              options: ['Doubler la quantité d\'eau', 'Arrêter complètement l\'arrosage pour faciliter le séchage des tuniques', 'Arroser avec de l\'eau chaude', 'Inonder la parcelle'],
              bonneReponseIndex: 1,
              explication: 'Stopper l\'arrosage permet aux bulbes de sécher et garantit une conservation de plusieurs mois sans pourriture.',
            ),
            QuestionQuiz(
              id: 208,
              question: 'Quel signe indique que l\'oignon est prêt à être déterré ?',
              options: ['Les feuilles deviennent géantes', 'Le collet se ramollit et le feuillage se couche naturellement au sol', 'Des fleurs violettes apparaissent', 'La terre devient rouge'],
              bonneReponseIndex: 1,
              explication: 'La tombaison du feuillage est le signal naturel que le bulbe a terminé sa phase de grossissement.',
            ),
            QuestionQuiz(
              id: 209,
              question: 'Comment stocker au mieux les oignons récoltés en climat chaud ?',
              options: ['Enfermés dans des sacs plastiques étanches', 'Dans un endroit ombragé, sec et bien ventilé sur claies', 'Au soleil direct sur le goudron', 'Sous un tas de paille mouillée'],
              bonneReponseIndex: 1,
              explication: 'L\'aération constante est la règle d\'or pour éviter le pourrissement bactérien des bulbes.',
            ),
          ],
        ),
      ],
    ),

    // ── MONDE 3 : Grandes Cultures (Maïs, Soja, Riz, Manioc) ──
    MondeQuiz(
      id: 3,
      nom: 'Grandes Cultures',
      description: 'Maïs abondant, soja protéiné et céréales locales',
      icone: '🌽',
      niveaux: [
        NiveauQuiz(
          id: 7,
          mondeId: 3,
          titre: 'Niveau 7 : Le Géant du Maïs',
          description: 'Densité de semis, fertilisation et lutte contre la chenille',
          questions: [
            QuestionQuiz(
              id: 301,
              question: 'La redoutable chenille légionnaire d\'automne s\'attaque en priorité à :',
              options: ['L\'écorce de la tige', 'Le cornet central et les jeunes feuilles du maïs', 'Les racines profondes', 'La terre autour du plant'],
              bonneReponseIndex: 1,
              explication: 'La chenille se loge au cœur du cornet végétatif et s\'y nourrit en y laissant des sciures caractéristiques.',
            ),
            QuestionQuiz(
              id: 302,
              question: 'Quelle est la distance recommandée entre les lignes pour une culture de maïs amélioré ?',
              options: ['20 cm', '75 à 80 cm entre lignes et 40 cm entre poquets', '2 mètres', '5 mètres'],
              bonneReponseIndex: 1,
              explication: 'Cet écartement permet un peuplement optimal d\'environ 50 000 à 60 000 pieds/ha sans compétition excessive.',
            ),
            QuestionQuiz(
              id: 303,
              question: 'Pourquoi l\'apport de fumure de fond est-il essentiel avant le labour du maïs ?',
              options: ['Pour donner une bonne odeur', 'Pour fournir des nutriments stables qui seront absorbés tout au long du cycle', 'Pour attirer les oiseaux', 'Pour repousser le vent'],
              bonneReponseIndex: 1,
              explication: 'La matière organique enfouie améliore la rétention d\'eau et libère progressivement l\'azote et le phosphore.',
            ),
          ],
        ),
        NiveauQuiz(
          id: 8,
          mondeId: 3,
          titre: 'Niveau 8 : La Puissance du Soja',
          description: 'Nodules azotés, rotation culturale et maturité',
          questions: [
            QuestionQuiz(
              id: 304,
              question: 'Quel super-pouvoir possède le soja (et les légumineuses) pour le sol ?',
              options: ['Il fabrique de l\'or', 'Il fixe l\'azote de l\'air dans le sol grâce à ses nodosités racinaires', 'Il boit toute l\'eau salée', 'Il détruit tous les champignons'],
              bonneReponseIndex: 1,
              explication: 'Les bactéries symbiotiques (Rhizobium) captent l\'azote de l\'air et enrichissent naturellement le sol pour la culture suivante.',
            ),
            QuestionQuiz(
              id: 305,
              question: 'Comment vérifier que les nodosités sur les racines de soja sont actives et fixent bien l\'azote ?',
              options: ['Elles doivent être noires et dures', 'En les écrasant, l\'intérieur doit être rosé ou rougeâtre', 'Elles doivent flotter sur l\'eau', 'Elles émettent de la lumière'],
              bonneReponseIndex: 1,
              explication: 'La couleur rouge/rose est due à la leghémoglobine, preuve indiscutable que la fixation d\'azote est active.',
            ),
            QuestionQuiz(
              id: 306,
              question: 'Pourquoi alterner maïs et soja (rotation des cultures) sur une même parcelle est-il recommandé ?',
              options: ['Pour que le paysage change de couleur', 'Pour briser le cycle des maladies et enrichir le sol sans engrais chimique', 'Pour empêcher la pluie de tomber', 'Pour réduire le rendement'],
              bonneReponseIndex: 1,
              explication: 'La rotation casse les cycles des ravageurs et permet au maïs de profiter de l\'azote laissé par le soja précédent.',
            ),
          ],
        ),
        NiveauQuiz(
          id: 9,
          mondeId: 3,
          titre: 'Niveau 9 : Manioc & Céréales de Savane',
          description: 'Sorgho, mil résistant et boutures saines',
          questions: [
            QuestionQuiz(
              id: 307,
              question: 'Quelle céréale est la plus résistante aux poches de sécheresse dans les zones arides ?',
              options: ['Le maïs doux', 'Le sorgho ou le mil', 'Le blé tendre', 'La salade'],
              bonneReponseIndex: 1,
              explication: 'Le sorgho et le mil ont un système racinaire profond et des feuilles cireuses qui résistent à la chaleur extrême.',
            ),
            QuestionQuiz(
              id: 308,
              question: 'Pour éviter la maladie de la mosaïque du manioc, quelle est la règle d\'or ?',
              options: ['Utiliser des boutures certifiées saines et tolérantes à la mosaïque', 'Arroser avec de l\'eau bouillante', 'Planter uniquement à midi', 'Enterrer du fer rouillé'],
              bonneReponseIndex: 0,
              explication: 'Le virus se transmettant par les boutures infectées et l\'aleurode, le choix de boutures saines est le rempart n°1.',
            ),
            QuestionQuiz(
              id: 309,
              question: 'Dans quel sens faut-il planter une bouture de manioc ?',
              options: ['Tête en bas', 'Yeux orientés vers le haut pour permettre aux bourgeons de se développer', 'À l\'horizontale pliée en deux', 'Peu importe le sens'],
              bonneReponseIndex: 1,
              explication: 'Planter les bourgeons vers le haut garantit une émergence rapide des tiges et une formation symétrique des tubercules.',
            ),
          ],
        ),
      ],
    ),

    // ── MONDE 4 : Défense des Cultures & Biopesticides ──
    MondeQuiz(
      id: 4,
      nom: 'Bio-Défense',
      description: 'Purins naturels, pièges et santé sans poison',
      icone: '🌿',
      niveaux: [
        NiveauQuiz(
          id: 10,
          mondeId: 4,
          titre: 'Niveau 10 : Le Neem, l\'Arbre Pharmacie',
          description: 'Préparation et dosage de l\'extrait de graines de neem',
          questions: [
            QuestionQuiz(
              id: 401,
              question: 'Quelle substance active insecticide contient la graine de Neem (Azadirachta indica) ?',
              options: ['La caféine', 'L\'azadirachtine', 'La nicotine', 'Le chlore'],
              bonneReponseIndex: 1,
              explication: 'L\'azadirachtine perturbe le développement des insectes ravageurs et coupe leur appétit sans tuer les abeilles.',
            ),
            QuestionQuiz(
              id: 402,
              question: 'Pourquoi ajoute-t-on quelques gouttes de savon liquide au purin de neem avant pulvérisation ?',
              options: ['Pour nettoyer les feuilles comme du linge', 'Pour jouer le rôle de mouillant et faire adhérer la solution sur les feuilles', 'Pour tuer la plante', 'Pour parfumer le champ'],
              bonneReponseIndex: 1,
              explication: 'Le savon casse la tension de l\'eau et permet au biopesticide de se coller uniformément sur la surface cireuse des feuilles.',
            ),
            QuestionQuiz(
              id: 403,
              question: 'Quand faut-il pulvériser les biopesticides naturels pour une efficacité maximale ?',
              options: ['À 14h sous un soleil de plomb', 'En fin d\'après-midi vers 17h au coucher du soleil', 'Pendant qu\'il pleut fort', 'Au milieu de la nuit'],
              bonneReponseIndex: 1,
              explication: 'Les rayons UV du soleil détruisent rapidement les molécules végétales. Traiter le soir prolonge leur action toute la nuit.',
            ),
          ],
        ),
        NiveauQuiz(
          id: 11,
          mondeId: 4,
          titre: 'Niveau 11 : Alliés du Jardinier',
          description: 'Coccinelles, chrysopes et équilibre biologique',
          questions: [
            QuestionQuiz(
              id: 404,
              question: 'Une seule coccinelle adulte peut dévorer chaque jour environ :',
              options: ['1 puceron par semaine', '50 à 100 pucerons par jour', 'Des cailloux', 'Des feuilles de salade'],
              bonneReponseIndex: 1,
              explication: 'La coccinelle et ses larves sont de redoutables prédatrices naturelles de pucerons et cochenilles.',
            ),
            QuestionQuiz(
              id: 405,
              question: 'Quel est le danger majeur de l\'utilisation abusive de pesticides chimiques non homologués ?',
              options: ['Les légumes deviennent trop gros', 'Destruction des pollinisateurs, pollution des nappes phréatiques et risques de cancer', 'La terre devient bleue', 'Les mauvaises herbes disparaissent à jamais'],
              bonneReponseIndex: 1,
              explication: 'Les pesticides non contrôlés empoisonnent l\'agriculteur, le consommateur et tuent les insectes utiles qui protégeaient les récoltes.',
            ),
            QuestionQuiz(
              id: 406,
              question: 'Comment fabriquer un piège économique contre la mouche des fruits (bactrocera) ?',
              options: ['Une bouteille plastique avec des trous, du jus de mangue ou levure et un peu d\'eau savonneuse', 'Un miroir brillant', 'Un filet en coton épais', 'Une bougie allumée'],
              bonneReponseIndex: 0,
              explication: 'Les mouches sont attirées par l\'odeur de fermentation, entrent par les petits trous et se noient sans aucun produit chimique toxique.',
            ),
          ],
        ),
        NiveauQuiz(
          id: 12,
          mondeId: 4,
          titre: 'Niveau 12 : Barrières & Répulsifs',
          description: 'Piment, ail, cendre de bois et pièges jaunes',
          questions: [
            QuestionQuiz(
              id: 407,
              question: 'Pourquoi saupoudre-t-on de la cendre de bois tamisée autour des jeunes plants de chou ou laitue ?',
              options: ['Pour chauffer la plante', 'Pour créer une barrière rugueuse contre les limaces, escargots et chenilles', 'Pour remplacer l\'eau', 'Pour masquer l\'odeur de la terre'],
              bonneReponseIndex: 1,
              explication: 'La cendre assèche et irrite le corps mou des gastéropodes et apporte de la potasse au sol.',
            ),
            QuestionQuiz(
              id: 408,
              question: 'La solution concentrée à base d\'ail et de piment pilé agit principalement comme :',
              options: ['Un engrais liquide', 'Un puissant répulsif olfactif et gustatif contre les insectes broyeurs et rongeurs', 'Un colorant pour les fruits', 'Un désherbant total'],
              bonneReponseIndex: 1,
              explication: 'La capsaïcine du piment et le soufre de l\'ail brûlent et chassent chenilles, criquets et lapins sans polluer.',
            ),
            QuestionQuiz(
              id: 409,
              question: 'Les pièges collants de couleur JAUNE placés dans les serres attirent particulièrement :',
              options: ['Les oiseaux', 'Les aleurodes (mouches blanches) et pucerons ailés', 'Les vers de terre', 'Les chauves-souris'],
              bonneReponseIndex: 1,
              explication: 'La couleur jaune vif stimule l\'instinct d\'atterrissage des mouches blanches qui restent engluées sur le piège.',
            ),
          ],
        ),
      ],
    ),

    // ── MONDE 5 : Élevage & Aviculture Locale ──
    MondeQuiz(
      id: 5,
      nom: 'Élevage Durable',
      description: 'Poulets locaux, petits ruminants et santé animale',
      icone: '🐔',
      niveaux: [
        NiveauQuiz(
          id: 13,
          mondeId: 5,
          titre: 'Niveau 13 : Le Poulet Goliath & Bicyclette',
          description: 'Poussinage, litière propre et vaccination',
          questions: [
            QuestionQuiz(
              id: 501,
              question: 'Quelle est la maladie virale la plus meurtrière chez la volaille villageoise (poulets bicyclettes) ?',
              options: ['La grippe humaine', 'La maladie de Newcastle (peste aviaire)', 'Le mal de dents', 'La rage'],
              bonneReponseIndex: 1,
              explication: 'Newcastle peut décimer 90% d\'un poulailler en quelques jours. Seule la vaccination préventive (I-2) protège efficacement.',
            ),
            QuestionQuiz(
              id: 502,
              question: 'Pourquoi une litière sèche en copeaux de bois est-elle essentielle dans un poulailler ?',
              options: ['Pour faire un lit confortable', 'Pour absorber l\'humidité des fientes et empêcher le développement de la coccidiose', 'Pour nourrir les poussins', 'Pour isoler du bruit'],
              bonneReponseIndex: 1,
              explication: 'Une litière humide et tiède est le terrain de reproduction parfait des parasites intestinaux mortels chez les poussins.',
            ),
            QuestionQuiz(
              id: 503,
              question: 'Quelle plante locale riche en protéines peut être séchée et incorporée dans la ration des volailles ?',
              options: ['Les feuilles de Moringa oleifera', 'Les feuilles d\'eucalyptus', 'Les tiges de manioc amer', 'Le teck'],
              bonneReponseIndex: 0,
              explication: 'Le Moringa contient jusqu\'à 27% de protéines végétales, des vitamines A et renforce l\'immunité des volailles.',
            ),
          ],
        ),
        NiveauQuiz(
          id: 14,
          mondeId: 5,
          titre: 'Niveau 14 : Moutons & Chèvres',
          description: 'Déparasitage, alimentation et abri surélevé',
          questions: [
            QuestionQuiz(
              id: 504,
              question: 'Pourquoi conseille-t-on de construire des bergeries sur caillebotis (sol surélevé à lattes de bois) ?',
              options: ['Pour que les animaux voient le paysage', 'Pour que les urines et crottes tombent en dessous et gardent les pattes au sec', 'Pour faire plus cher', 'Pour attirer le vent'],
              bonneReponseIndex: 1,
              explication: 'Le sol surélevé protège les ovins et caprins du piétin (pourriture des sabots) et des parasites intestinaux.',
            ),
            QuestionQuiz(
              id: 505,
              question: 'À quelle fréquence minimale doit-on déparasiter les petits ruminants en zone tropicale humide ?',
              options: ['Une fois tous les 10 ans', 'Au moins 3 à 4 fois par an (au début et à la fin des saisons des pluies)', 'Jamais, ils se débrouillent', 'Tous les jours'],
              bonneReponseIndex: 1,
              explication: 'Les vers digestifs prolifèrent avec les pluies et affaiblissent le cheptel si le déparasitage n\'est pas planifié.',
            ),
            QuestionQuiz(
              id: 506,
              question: 'Quel bloc à lécher naturel peut-on fabriquer pour apporter minéraux et sel au bétail ?',
              options: ['Du ciment et du sucre', 'Un mélange sel marin, farine d\'os, argile et coquilles d\'huîtres pilées', 'De la boue séchée', 'Du sable et du piment'],
              bonneReponseIndex: 1,
              explication: 'Les pierres à lécher artisanales fournissent le sodium, calcium et phosphore indispensables pour la croissance osseuse et la lactation.',
            ),
          ],
        ),
        NiveauQuiz(
          id: 15,
          mondeId: 5,
          titre: 'Niveau 15 : L\'Agrobusiness Réussi',
          description: 'Calcul des coûts, vente groupée et valeur ajoutée',
          questions: [
            QuestionQuiz(
              id: 507,
              question: 'Pourquoi les producteurs ont-ils intérêt à vendre leurs récoltes à travers une coopérative plutôt qu\'isolés ?',
              options: ['Pour payer plus de taxes', 'Pour peser dans la négociation et obtenir un prix plus rémunérateur face aux grossistes', 'Pour donner leurs récoltes gratuitement', 'Pour vendre plus tard sans argent'],
              bonneReponseIndex: 1,
              explication: 'L\'union fait la force : le regroupement de l\'offre empêche les intermédiaires véreux d\'imposer des prix bradés.',
            ),
            QuestionQuiz(
              id: 508,
              question: 'Quelle étape permet à un producteur de maïs ou de manioc de tripler sa marge bénéficiaire ?',
              options: ['Brûler la moitié de la récolte', 'La transformation locale (farine panifiable, gari fin, amidon) et le conditionnement', 'Vendre tout le jour de la récolte au premier venu', 'Abandonner son champ'],
              bonneReponseIndex: 1,
              explication: 'Transformer la matière première crée de la valeur ajoutée locale et permet de stocker le produit sans urgence de mévente.',
            ),
            QuestionQuiz(
              id: 509,
              question: 'Quel est le premier outil de gestion qu\'un agriculteur moderne doit tenir à jour ?',
              options: ['Un cahier de dépenses et de recettes (cahier de bord de l\'exploitation)', 'Un compte TikTok', 'Une télé couleur au champ', 'Un costume cravate'],
              bonneReponseIndex: 0,
              explication: 'Savoir exactement combien ont coûté les semences, l\'engrais et la main-d\'œuvre est la seule façon de calculer son bénéfice réel.',
            ),
          ],
        ),
      ],
    ),
  ];

  /// Retourne un niveau par son identifiant
  static NiveauQuiz? getNiveau(int id) {
    for (final monde in mondes) {
      for (final n in monde.niveaux) {
        if (n.id == id) return n;
      }
    }
    return null;
  }

  /// Retourne le total de niveaux disponibles
  static int get totalNiveaux {
    int total = 0;
    for (final m in mondes) {
      total += m.niveaux.length;
    }
    return total;
  }

  /// Génère 3 questions aléatoires mais déterministes pour le "Quiz du Jour"
  /// basé sur le jour de l'année (100% hors-ligne, identique pour tous le même jour)
  static List<QuestionQuiz> getQuizDuJour() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    
    // Récupérer toutes les questions
    final toutesQuestions = <QuestionQuiz>[];
    for (final m in mondes) {
      for (final n in m.niveaux) {
        toutesQuestions.addAll(n.questions);
      }
    }

    if (toutesQuestions.isEmpty) return [];

    final index1 = (dayOfYear * 3) % toutesQuestions.length;
    final index2 = (dayOfYear * 3 + 1) % toutesQuestions.length;
    final index3 = (dayOfYear * 3 + 2) % toutesQuestions.length;

    return [
      toutesQuestions[index1],
      toutesQuestions[index2],
      toutesQuestions[index3],
    ];
  }
}
