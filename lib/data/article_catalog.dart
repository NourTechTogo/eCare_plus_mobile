import 'package:flutter/material.dart';

class ArticleSection {
  final String title;
  final String body;
  const ArticleSection(this.title, this.body);
}

class ArticleSource {
  final String title;
  final String url;
  const ArticleSource(this.title, this.url);
}

class ArticlePreview {
  final String id, title, category, collection, introduction;
  final List<ArticleSection> sections;
  final List<ArticleSource> sources;
  final Color background, accent;
  final int artwork;
  Color get textAccent => Color.lerp(accent, const Color(0xFF0D1B2A), .25)!;
  const ArticlePreview({
    required this.id,
    required this.title,
    required this.category,
    required this.collection,
    required this.introduction,
    required this.sections,
    required this.sources,
    required this.background,
    required this.accent,
    required this.artwork,
  });
}

const featuredArticle = ArticlePreview(
  id: 'welcome',
  title: 'Mieux comprendre sa santé, un article à la fois',
  category: 'Bien-être',
  collection: 'À la une',
  introduction:
      'S’informer peut aider à mieux participer aux décisions qui concernent sa santé. Quelques repères simples rendent les échanges avec les professionnels plus clairs et plus utiles.',
  sections: [
    ArticleSection(
      'Partir de ses questions',
      'Une consultation est aussi un moment d’échange. Notez les sujets qui vous préoccupent, les changements observés et les questions que vous ne voulez pas oublier. Commencez par le point qui compte le plus pour vous.',
    ),
    ArticleSection(
      'Apporter les bonnes informations',
      'Selon le motif du rendez-vous, vos résultats récents, la liste de vos traitements et un relevé de mesures peuvent aider le professionnel à comprendre votre situation. Demandez-lui ce qu’il est utile d’apporter et comment noter les mesures à réaliser.',
    ),
    ArticleSection(
      'Repartir avec des repères',
      'Avant de terminer, reformulez ce que vous avez compris et demandez les prochaines étapes : un examen, un suivi ou un nouveau rendez-vous. Si une consigne n’est pas claire, faites-la préciser. Vous pouvez noter les réponses pour les retrouver ensuite.',
    ),
  ],
  sources: [
    ArticleSource(
      'Assurance Maladie — Préparer ses questions pour une consultation',
      'https://www.ameli.fr/assure/sante/themes/diabete-adulte/diabete-suivi/surveillance-fondamentaux',
    ),
  ],
  background: Color(0xFFE1F2FC),
  accent: Color(0xFF168BC4),
  artwork: 0,
);

const articlePreviews = [
  ArticlePreview(
    id: 'glucose',
    title: 'Comprendre sa glycémie',
    category: 'Diabète',
    collection: 'Comprendre votre santé',
    introduction:
        'La glycémie correspond à la quantité de glucose dans le sang. Elle varie au cours de la journée et s’interprète selon le contexte, les objectifs convenus avec le médecin et le suivi prévu pour chacun.',
    sections: [
      ArticleSection(
        'Une mesure dépend du moment',
        'Un résultat peut être influencé par un repas, une activité physique, le stress, une maladie ou certains médicaments. Une mesure isolée ne résume donc pas à elle seule l’équilibre du diabète. La fréquence des contrôles et les moments où les réaliser dépendent de votre situation et des consignes de votre équipe soignante.',
      ),
      ArticleSection(
        'Noter ce qui entoure le résultat',
        'Inscrire la date, l’heure et les circonstances de la mesure peut rendre le relevé plus utile. Notez, si cela s’applique, le lien avec un repas ou une activité, ou un événement inhabituel comme une fièvre. Ces éléments peuvent aider à repérer des tendances et à en parler lors d’un rendez-vous.',
      ),
      ArticleSection(
        'Le bilan complète l’autosurveillance',
        'L’hémoglobine glyquée, ou HbA1c, est mesurée par une prise de sang et aide le médecin à apprécier l’évolution de la glycémie sur plusieurs semaines. Elle apporte une information différente d’une mesure réalisée à la maison. Demandez quels résultats vous concernent et quels objectifs ont été fixés pour vous ; ne modifiez pas votre traitement sans avis médical.',
      ),
    ],
    sources: [
      ArticleSource(
        'Assurance Maladie — Autosurveillance de la glycémie',
        'https://www.ameli.fr/assure/sante/themes/diabete-adulte/diabete-suivi/autosurveillance-glycemie',
      ),
      ArticleSource(
        'Assurance Maladie — Le suivi du diabète',
        'https://www.ameli.fr/assure/sante/themes/diabete-adulte/diabete-suivi/surveillance-fondamentaux',
      ),
    ],
    background: Color(0xFFE9E5F6),
    accent: Color(0xFF7963AD),
    artwork: 1,
  ),
  ArticlePreview(
    id: 'pressure',
    title: 'La tension, en mots simples',
    category: 'Hypertension',
    collection: 'Comprendre votre santé',
    introduction:
        'La tension artérielle décrit la pression du sang dans les artères. Elle s’exprime avec deux valeurs : la pression systolique, lorsque le cœur se contracte, et la pression diastolique, lorsqu’il se relâche.',
    sections: [
      ArticleSection(
        'Pourquoi les valeurs peuvent varier',
        'La tension n’est pas identique à chaque instant. L’activité, les émotions et les conditions de mesure peuvent la faire varier. C’est pourquoi un professionnel de santé peut demander plusieurs mesures à domicile plutôt que de conclure à partir d’un seul chiffre.',
      ),
      ArticleSection(
        'Préparer une mesure à domicile',
        'Suivez d’abord les consignes données par votre médecin. En général, il est conseillé de s’installer dans un endroit calme, de rester assis quelques minutes avant la mesure, de ne pas parler pendant celle-ci et d’utiliser toujours le même bras. Notez les deux valeurs, ainsi que la date et l’heure.',
      ),
      ArticleSection(
        'Partager le relevé avec un professionnel',
        'Le médecin vous indique la durée et le rythme du relevé à effectuer. Il interprète les résultats en tenant compte de votre situation et des conditions de mesure. Si un chiffre vous inquiète ou si vous ne savez pas comment poursuivre, demandez conseil plutôt que de modifier seul un traitement.',
      ),
    ],
    sources: [
      ArticleSource(
        'Assurance Maladie — Prendre sa tension artérielle à domicile',
        'https://www.ameli.fr/assure/sante/bons-gestes/soins/prendre-tension-arterielle-domicile',
      ),
    ],
    background: Color(0xFFF9E3DD),
    accent: Color(0xFFC96959),
    artwork: 2,
  ),
  ArticlePreview(
    id: 'rest',
    title: 'Faire une place au repos',
    category: 'Bien-être',
    collection: 'Prendre soin de soi',
    introduction:
        'Le sommeil et le repos participent au bien-être, mais les besoins et les rythmes varient d’une personne à l’autre. Observer ses habitudes peut aider à repérer ce qui facilite — ou perturbe — ses nuits.',
    sections: [
      ArticleSection(
        'Installer des repères réguliers',
        'Des horaires de lever assez réguliers et une chambre calme, sombre et confortable peuvent aider à créer un cadre propice au sommeil. Être attentif aux signes de fatigue permet aussi de choisir un moment adapté pour se coucher, plutôt que de lutter contre l’endormissement.',
      ),
      ArticleSection(
        'Alléger la fin de journée',
        'Certaines habitudes du soir peuvent retarder l’endormissement : les écrans, les notifications ou les boissons excitantes consommées tardivement. Vous pouvez tester une activité calme, réduire progressivement la lumière et garder les appareils à distance pendant la nuit. Trouvez les changements qui sont réalistes pour vous.',
      ),
      ArticleSection(
        'Observer avant de chercher une solution',
        'Noter pendant quelques jours les heures de coucher et de lever, les réveils et l’énergie au cours de la journée peut faire apparaître des régularités. Si les difficultés durent, retentissent sur votre quotidien ou s’accompagnent d’une forte somnolence, parlez-en à un professionnel de santé.',
      ),
    ],
    sources: [
      ArticleSource(
        'Assurance Maladie — Comment mieux dormir à l’âge adulte ?',
        'https://www.ameli.fr/assure/sante/themes/insomnie-adulte/vivre-insomnie',
      ),
    ],
    background: Color(0xFFE6EAF8),
    accent: Color(0xFF677DB9),
    artwork: 3,
  ),
  ArticlePreview(
    id: 'balance',
    title: 'Retrouver son équilibre au quotidien',
    category: 'Bien-être',
    collection: 'Prendre soin de soi',
    introduction:
        'Prendre soin de soi ne repose pas sur une routine parfaite. De petits moments de mouvement, de repos et d’attention à ses besoins peuvent s’intégrer au quotidien, à un rythme compatible avec ses capacités.',
    sections: [
      ArticleSection(
        'Le mouvement ne se limite pas au sport',
        'Marcher pour un trajet, jardiner, faire quelques tâches ou prendre les escaliers sont aussi des façons de bouger. L’activité peut être répartie dans la journée et adaptée à vos possibilités. Commencer doucement et augmenter progressivement aide à installer une habitude durable.',
      ),
      ArticleSection(
        'Interrompre les longues périodes assises',
        'Quand une journée se déroule surtout assis, se lever de temps en temps, marcher un peu ou s’étirer peut réduire la sédentarité. Choisissez un rappel ou associez ces pauses à des moments déjà présents dans votre journée, comme la fin d’un appel ou d’une tâche.',
      ),
      ArticleSection(
        'Choisir un objectif qui vous convient',
        'Un objectif simple — une courte marche, une pause active ou une activité que vous aimez — est souvent plus facile à maintenir qu’un changement trop ambitieux. Si vous avez une maladie chronique, des douleurs ou un doute sur la sécurité d’une activité, demandez conseil à votre médecin avant de modifier fortement vos habitudes.',
      ),
    ],
    sources: [
      ArticleSource(
        'Assurance Maladie — Activité physique et santé',
        'https://www.ameli.fr/assure/sante/themes/activite-physique-sante/age-activite-physique',
      ),
    ],
    background: Color(0xFFE0EFE7),
    accent: Color(0xFF4F8975),
    artwork: 4,
  ),
  ArticlePreview(
    id: 'food',
    title: 'Alimentation : les bonnes questions',
    category: 'Diabète',
    collection: 'Les petits gestes qui comptent',
    introduction:
        'Manger équilibré ne signifie pas suivre un menu identique pour tout le monde. Les habitudes, les goûts, le budget et la situation de santé comptent aussi. Quelques repères peuvent aider à varier les repas sans chercher la perfection.',
    sections: [
      ArticleSection(
        'Varier les aliments au fil des repas',
        'Les recommandations françaises invitent notamment à augmenter la place des fruits et légumes, des légumes secs et des fruits à coque non salés, et à aller vers des céréales complètes. Les produits de saison et les préparations faites maison peuvent aussi aider à diversifier les choix.',
      ),
      ArticleSection(
        'Observer ses habitudes sans jugement',
        'Pendant quelques jours, notez simplement les repas et les boissons qui composent vos journées. Cela peut révéler des habitudes auxquelles vous ne pensiez pas et fournir un point de départ pour une discussion. Il ne s’agit pas de compter ou de culpabiliser, mais de repérer ce qui vous convient et ce qui pourrait évoluer.',
      ),
      ArticleSection(
        'Adapter les conseils à sa situation',
        'Une maladie, un traitement, des allergies ou des difficultés d’accès à certains aliments peuvent changer les besoins. En cas de diabète, par exemple, les conseils alimentaires doivent tenir compte du suivi médical et des objectifs convenus. Un médecin ou un diététicien peut vous aider à trouver des ajustements adaptés, sans régime improvisé.',
      ),
    ],
    sources: [
      ArticleSource(
        'Manger Bouger — Recommandations alimentaires pour les adultes',
        'https://www.mangerbouger.fr/manger-mieux/a-tout-age-et-a-chaque-etape-de-la-vie/les-recommandations-alimentaires-pour-les-adultes',
      ),
      ArticleSource(
        'Assurance Maladie — Gérer son alimentation en cas de diabète',
        'https://www.ameli.fr/assure/sante/themes/diabete-adulte/diabete-vivre-quotidien/equilibre-alimentaire/gerer-alimentation-repas',
      ),
    ],
    background: Color(0xFFF9EED6),
    accent: Color(0xFFAD8239),
    artwork: 4,
  ),
  ArticlePreview(
    id: 'tracking',
    title: 'Un suivi qui vous ressemble',
    category: 'Hypertension',
    collection: 'Les petits gestes qui comptent',
    introduction:
        'Un relevé utile est d’abord un relevé qui répond à une question de santé et que vous pouvez tenir sans difficulté. Le professionnel qui vous suit peut vous aider à choisir quoi noter, à quel moment et pendant combien de temps.',
    sections: [
      ArticleSection(
        'Définir ce qu’il faut suivre',
        'Selon la situation, il peut s’agir de mesures de tension ou de glycémie, de symptômes ou d’un autre élément précis. Évitez de multiplier les contrôles sans consigne : les données n’ont de sens que replacées dans leur contexte et selon un objectif défini avec un professionnel.',
      ),
      ArticleSection(
        'Garder un relevé lisible',
        'Notez la date et l’heure, la valeur demandée et, si cela aide à l’interprétation, les circonstances particulières. Pour l’automesure de la tension, suivez le rythme communiqué par votre médecin et apportez le relevé au rendez-vous. Des notes régulières et simples sont souvent plus faciles à relire qu’un journal très détaillé.',
      ),
      ArticleSection(
        'Faire du relevé un support de dialogue',
        'Un relevé sert à discuter d’une évolution, pas à poser soi-même un diagnostic. Signalez les mesures ou symptômes qui vous inquiètent et demandez comment réagir dans votre cas. N’arrêtez pas et ne modifiez pas un traitement en vous fondant uniquement sur une valeur ou une courbe.',
      ),
    ],
    sources: [
      ArticleSource(
        'Assurance Maladie — Le suivi du diabète',
        'https://www.ameli.fr/assure/sante/themes/diabete-adulte/diabete-suivi/surveillance-fondamentaux',
      ),
      ArticleSource(
        'Assurance Maladie — Prendre sa tension à domicile',
        'https://www.ameli.fr/assure/sante/bons-gestes/soins/prendre-tension-arterielle-domicile',
      ),
    ],
    background: Color(0xFFDDEEF4),
    accent: Color(0xFF41899C),
    artwork: 2,
  ),
];
