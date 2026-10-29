// Banque de 31 conseils agricoles pratiques du jour (1 pour chaque jour du mois).
// 100% hors-ligne, renouvelé automatiquement selon la date locale du téléphone.

class ConseilAgricole {
  final int id;
  final String titre;
  final String categorie;
  final String texte;
  final String astuceCle;

  const ConseilAgricole({
    required this.id,
    required this.titre,
    required this.categorie,
    required this.texte,
    required this.astuceCle,
  });
}

class ConseilsData {
  static const List<ConseilAgricole> conseils = [
    ConseilAgricole(
      id: 1,
      titre: 'Protéger vos tomates de la mouche blanche',
      categorie: 'Maraîchage',
      texte: 'Les mouches blanches transmettent le virus de l\'enroulement des feuilles de tomate. Installez des bandes ou plaques jaunes engluées d\'huile végétale à 20 cm au-dessus des plants pour capturer les adultes dès leur arrivée.',
      astuceCle: 'La couleur jaune vif attire irrésistiblement les aleurodes.',
    ),
    ConseilAgricole(
      id: 2,
      titre: 'La cendre de bois contre les chenilles et limaces',
      categorie: 'Protection Bio',
      texte: 'Saupoudrez de la cendre de bois bien tamisée autour du collet de vos choux et laitues. La texture abrasive déshydrate le corps mou des insectes rampants et apporte une excellente dose de potasse au sol.',
      astuceCle: 'Renouvelez l\'application après chaque forte averse.',
    ),
    ConseilAgricole(
      id: 3,
      titre: 'Paillage : divisez vos arrosages par deux',
      categorie: 'Gestion de l\'Eau',
      texte: 'En saison sèche ou sous forte chaleur, recouvrez vos planches de maraîchage d\'une couche de 5 cm de paille sèche ou de feuilles de maïs. Vous réduirez l\'évaporation de 50% et garderez la terre fraîche pour les racines.',
      astuceCle: 'Laissez un petit espace de 2 cm autour de la tige pour éviter les pourritures.',
    ),
    ConseilAgricole(
      id: 4,
      titre: 'Nodules de soja : l\'azote gratuit pour votre champ',
      categorie: 'Grandes Cultures',
      texte: 'Avant de récolter votre soja, déterrez un plant et observez les racines. Des nodosités roses à l\'intérieur signifient que le soja a injecté gratuitement de l\'azote dans votre terre pour le maïs de la saison suivante.',
      astuceCle: 'Ne brûlez jamais les résidus de soja après la récolte, enfouissez-les.',
    ),
    ConseilAgricole(
      id: 5,
      titre: 'Biopesticide maison à l\'ail et au piment',
      categorie: 'Protection Bio',
      texte: 'Pilez 3 gousses d\'ail et 2 piments forts dans 1 litre d\'eau tiède. Laissez macérer 24 heures, filtrez puis ajoutez 1 cuillère de savon noir. Pulvérisez le soir pour faire fuir pucerons, chenilles et criquets.',
      astuceCle: 'Traitez toujours le soir pour que les principes actifs agissent toute la nuit.',
    ),
    ConseilAgricole(
      id: 6,
      titre: 'Le purin de neem pour bloquer la mue des insectes',
      categorie: 'Protection Bio',
      texte: 'Pilonnez 500 grammes de graines de neem séchées dans 10 litres d\'eau. Laissez reposer une nuit. Cette solution bloque le système hormonal des insectes ravageurs et coupe leur appétit sans danger pour les vers de terre.',
      astuceCle: 'Filtrez avec un tissu fin pour ne pas boucher la buse du pulvérisateur.',
    ),
    ConseilAgricole(
      id: 7,
      titre: 'Arrosage efficace : le matin plutôt qu\'à midi',
      categorie: 'Gestion de l\'Eau',
      texte: 'Arroser en plein soleil fait évaporer 60% de l\'eau avant même qu\'elle n\'atteigne les racines et risque de brûler les feuilles par effet loupe. Privilégiez un arrosage copieux au lever du soleil ou après 17h.',
      astuceCle: 'Arrosez le pied de la plante et jamais les feuilles en maraîchage.',
    ),
    ConseilAgricole(
      id: 8,
      titre: 'Vaccin I-2 : blindez vos poulets locaux contre Newcastle',
      categorie: 'Élevage',
      texte: 'La peste aviaire décime les poulaillers villageois à chaque changement de saison. Le vaccin I-2 thermostable s\'administre en une seule goutte dans l\'œil et protège vos sujets pendant 4 mois sans chaîne de froid stricte.',
      astuceCle: 'Vaccinez tous les poulets du village le même jour pour un effet protecteur total.',
    ),
    ConseilAgricole(
      id: 9,
      titre: 'Rotation des cultures : brisez le cycle des maladies',
      categorie: 'Sols & Agronomie',
      texte: 'Ne replantez jamais de tomates ou de piments sur la même parcelle deux saisons de suite. Alternez avec du maïs, du niébé ou du soja pour affamer les champignons et nématodes installés dans le sol.',
      astuceCle: 'Après une solanacée (tomate), plantez une légumineuse (haricot/soja).',
    ),
    ConseilAgricole(
      id: 10,
      titre: 'Boutures de manioc : plantez dans le bon sens',
      categorie: 'Grandes Cultures',
      texte: 'Vérifiez toujours l\'orientation des yeux de la bouture de manioc avant de l\'enfoncer dans la terre : ils doivent pointer vers le ciel. Une bouture plantée à l\'envers épuise ses réserves et retarde la levée de 3 semaines.',
      astuceCle: 'Enfoncez la bouture aux deux tiers en position inclinée à 45°.',
    ),
    ConseilAgricole(
      id: 11,
      titre: 'L\'arbre Faidherbia albida : engrais vivant pour céréales',
      categorie: 'Agroforesterie',
      texte: 'Conservez les arbres Faidherbia dans vos champs de céréales. Contrairement aux autres arbres, il perd ses feuilles en saison des pluies, n\'ombrage pas le mil ni le sorgho et fertilise la terre à chaque chute de feuilles.',
      astuceCle: 'Un champ arboré de Faidherbia peut doubler son rendement sans engrais minéral.',
    ),
    ConseilAgricole(
      id: 12,
      titre: 'Gourmands de tomate : taillez pour de gros fruits',
      categorie: 'Maraîchage',
      texte: 'Supprimez régulièrement les petites tiges secondaires qui poussent à l\'aisselle des feuilles de tomate. Cette taille concentre toute la sève vers la tige principale et donne des fruits beaucoup plus gros et fermes.',
      astuceCle: 'Taillez avec les doigts un jour ensoleillé pour une cicatrisation rapide.',
    ),
    ConseilAgricole(
      id: 13,
      titre: 'Conservation du maïs : le test de l\'ongle et du sel',
      categorie: 'Stockage & Vente',
      texte: 'Avant de mettre votre maïs en sac, assurez-vous que l\'humidité est inférieure à 13%. Si votre ongle laisse une marque profonde dans le grain, il est encore trop humide et va moisir. Séchez-le 2 jours de plus au soleil.',
      astuceCle: 'Le sel fin secoué dans un bocal avec les grains ne doit pas coller aux parois.',
    ),
    ConseilAgricole(
      id: 14,
      titre: 'Moringa séché : l\'aliment miracle des volailles',
      categorie: 'Élevage',
      texte: 'Séchez des feuilles de Moringa à l\'ombre puis réduisez-les en poudre. En incorporant 5% de cette poudre dans la provende de vos poules, vous obtenez des jaunes d\'œufs bien orangés et une ponte régulière.',
      astuceCle: 'Le séchage à l\'ombre préserve toutes les vitamines du Moringa.',
    ),
    ConseilAgricole(
      id: 15,
      titre: 'Détecter la chenille légionnaire d\'automne tôt',
      categorie: 'Grandes Cultures',
      texte: 'Inspectez vos champs de maïs dès le 10ème jour après la levée. Repérez les sciures fraîches au cœur du cornet : c\'est le signe d\'une larve jeune. C\'est à ce stade précoce que les traitements naturels au neem sont les plus mortels.',
      astuceCle: 'Traitez directement le cornet avec quelques pincées de cendre ou sable fin.',
    ),
    ConseilAgricole(
      id: 16,
      titre: 'Oignons de conservation : stoppez l\'eau 15 jours avant',
      categorie: 'Maraîchage',
      texte: 'Pour que vos oignons se conservent 6 mois sans pourrir dans le grenier, coupez tout arrosage deux semaines avant la récolte. Attendez que le feuillage soit couché à 70% sur le sol avant de déterrer.',
      astuceCle: 'Laissez ressuyer les bulbes 3 jours à l\'ombre après arrachage.',
    ),
    ConseilAgricole(
      id: 17,
      titre: 'Litière sèche en aviculture : zéro coccidiose',
      categorie: 'Élevage',
      texte: 'Ne laissez jamais une fuite d\'abreuvoir mouiller la litière de vos poussins. Une litière humide et tiède est une bombe à retardement pour les parasites intestinaux. Retirez immédiatement toute zone humide.',
      astuceCle: 'Saupoudrez un peu de chaux éteinte sous la litière fraîche pour assainir.',
    ),
    ConseilAgricole(
      id: 18,
      titre: 'Œillet d\'Inde en bordure de piment',
      categorie: 'Maraîchage',
      texte: 'Plantez des pieds d\'œillet d\'Inde (marigold) tout autour de vos planches de piment et de tomate. Leurs racines dégagent une substance qui détruit les nématodes et leur odeur repousse les pucerons.',
      astuceCle: 'Une solution 100% naturelle et très esthétique pour vos parcelles.',
    ),
    ConseilAgricole(
      id: 19,
      titre: 'Fumier décomposé contre brûlure des racines',
      categorie: 'Sols & Agronomie',
      texte: 'N\'apportez jamais de fumier frais directement au pied de vos cultures maraîchères : en fermentant, il dégage une chaleur qui brûle les racines et propage des germes. Laissez-le composter au moins 2 mois.',
      astuceCle: 'Un compost mûr dégage une bonne odeur de terre de sous-bois.',
    ),
    ConseilAgricole(
      id: 20,
      titre: 'Cahier d\'exploitation : le secret des bénéfices réels',
      categorie: 'Agrobusiness',
      texte: 'Notez chaque semaine sur un cahier chaque dépense (semences, main-d\'œuvre, carburant motopompe) et chaque vente. Vous saurez exactement le coût de revient de votre bol de maïs pour ne plus jamais vendre à perte.',
      astuceCle: 'L\'agriculteur qui compte ses sous est celui qui investit et prospère.',
    ),
    ConseilAgricole(
      id: 21,
      titre: 'Bactrocera : le piège bouteille pour les mangues',
      categorie: 'Arboriculture',
      texte: 'Percez de petits trous de 5 mm sur une bouteille plastique vide. Remplissez-y un fond d\'eau mélangé à un peu de levure de boulanger et du sucre. Les mouches des fruits y entreront et ne ressortiront plus.',
      astuceCle: 'Suspendez 4 pièges par grand manguier 1 mois avant la récolte.',
    ),
    ConseilAgricole(
      id: 22,
      titre: 'Bergerie sur pilotis pour petits ruminants',
      categorie: 'Élevage',
      texte: 'Les moutons et chèvres supportent très mal l\'humidité au sol qui provoque la pourriture des sabots (piétin). Construisez un abri surélevé à lattes de bois : les crottes tombent et les bêtes dorment au sec.',
      astuceCle: 'Vous récolterez en dessous un engrais organique exceptionnel.',
    ),
    ConseilAgricole(
      id: 23,
      titre: 'Le savon noir liquide, mouillant naturel indispensable',
      categorie: 'Protection Bio',
      texte: 'Lorsque vous préparez une tisane ou macération de plantes pour traiter vos cultures, l\'eau a tendance à glisser sur les feuilles cireuses. Une cuillère de savon noir fait adhérer la solution comme de la colle.',
      astuceCle: 'Le savon étouffe aussi directement les pucerons et cochenilles.',
    ),
    ConseilAgricole(
      id: 24,
      titre: 'Densité de semis : ne semez pas trop serré',
      categorie: 'Grandes Cultures',
      texte: 'Mettre trop de graines par poquet ne donne pas plus de récolte : les tiges s\'étiolent, se battent pour l\'eau et font de petits épis. Démarier à 2 plants vigoureux par poquet garantit un rendement bien supérieur.',
      astuceCle: 'Faites le démariage quand le maïs a 3 à 4 vraies feuilles.',
    ),
    ConseilAgricole(
      id: 25,
      titre: 'Cul noir de la tomate : régulez vos arrosages',
      categorie: 'Maraîchage',
      texte: 'La tache noire sous la tomate n\'est pas un champignon, mais une carence en calcium provoquée par un arrosage irrégulier (terre trempée puis totalement desséchée). Arrosez régulièrement avec une quantité constante.',
      astuceCle: 'Apportez des coquilles d\'œufs broyées au compost pour enrichir en calcium.',
    ),
    ConseilAgricole(
      id: 26,
      titre: 'Conservation du niébé sans charançons',
      categorie: 'Stockage & Vente',
      texte: 'Pour conserver vos graines de haricot et niébé sans insecticide chimique dangereux, stockez-les dans des sacs hermétiques triple-fond (sacs PICS) ou mélangez-y de la cendre de bois tamisée bien sèche.',
      astuceCle: 'Les charançons meurent étouffés en moins de 10 jours sans oxygène.',
    ),
    ConseilAgricole(
      id: 27,
      titre: 'Déparasitage des ovins en début de saison pluvieuse',
      categorie: 'Élevage',
      texte: 'L\'arrivée des pluies fait éclore des milliers d\'œufs de vers parasites dans les pâturages. Déparasitez l\'ensemble de votre troupeau juste avant les premières pluies pour leur assurer une croissance vigoureuse.',
      astuceCle: 'Changez de molécule vermifuge d\'une année sur l\'autre.',
    ),
    ConseilAgricole(
      id: 28,
      titre: 'Sevrage des pépinières avant repiquage',
      categorie: 'Pépinières',
      texte: 'Cinq jours avant de repiquer vos plants de piment ou tomate au champ, réduisez de moitié l\'arrosage et enlevez le toit d\'ombrage. Ce stress contrôlé prépare les plants à résister au plein soleil du champ.',
      astuceCle: 'Repiquez toujours en fin d\'après-midi pour laisser la nuit aux racines.',
    ),
    ConseilAgricole(
      id: 29,
      titre: 'Vente groupée : négociez en position de force',
      categorie: 'Agrobusiness',
      texte: 'Si vous vendez vos 5 sacs de maïs isolé, l\'acheteur vous impose son prix. Si vous vous associez à 10 voisins pour proposer un camion de 100 sacs, c\'est vous qui fixez le prix et les commerçants viennent à vous.',
      astuceCle: 'Les coopératives agricoles sont les meilleurs boucliers anti-braderie.',
    ),
    ConseilAgricole(
      id: 30,
      titre: 'Pierre à lécher artisanale pour votre cheptel',
      categorie: 'Élevage',
      texte: 'Mélangez 2 parts de sel marin, 1 part d\'argile fine, 1 part de coquilles pilées et un peu d\'eau. Moulez dans une calebasse et faites sécher au soleil. Vos moutons et chèvres y trouveront tous leurs minéraux.',
      astuceCle: 'Placez la pierre sous un abri pour qu\'elle ne fonde pas à la pluie.',
    ),
    ConseilAgricole(
      id: 31,
      titre: 'Protéger la vie du sol : bannir le brûlis',
      categorie: 'Sols & Agronomie',
      texte: 'Brûler les résidus de récolte détruit la matière organique, tue les vers de terre et cuit le sol jusqu\'à 10 cm de profondeur. Préférez le fauchage et l\'enfouissement qui redonnent vie à votre terre.',
      astuceCle: 'La matière organique enfouie est votre assurance-sécheresse.',
    ),
  ];

  /// Récupère le conseil du jour selon la date du jour (déterministe, 100% hors-ligne)
  static ConseilAgricole getConseilDuJour() {
    final now = DateTime.now();
    // Index basé sur le jour du mois (1 à 31)
    final index = (now.day - 1) % conseils.length;
    return conseils[index];
  }
}
