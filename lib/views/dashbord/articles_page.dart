import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/article_catalog.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/article_cover.dart';
import '../../widgets/page_header.dart';

const _editorialBlue = AppColors.primary;

class ArticlesPage extends StatefulWidget {
  final bool showBack;
  const ArticlesPage({super.key, this.showBack = true});
  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  static const _storageKey = 'article_preview_favorites';
  final _search = TextEditingController();
  final _saved = <String>{};
  String _category = 'Tout';
  bool _favoritesOnly = false;
  late final Future<void> _loaded;

  @override
  void initState() {
    super.initState();
    _loaded = _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() => _saved.addAll(prefs.getStringList(_storageKey) ?? []));
      }
    } catch (_) {
      // Browsing remains available when local storage is unavailable.
    }
  }

  Future<void> _toggleSaved(ArticlePreview article) async {
    await _loaded;
    if (!mounted) return;
    setState(() {
      if (!_saved.remove(article.id)) _saved.add(article.id);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setStringList(_storageKey, _saved.toList())) {
        throw StateError('Save failed');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Favori conservé pour cette session. L’enregistrement local est indisponible.',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  void _reset() => setState(() {
    _search.clear();
    _category = 'Tout';
    _favoritesOnly = false;
  });

  Future<void> _openArticle(ArticlePreview article) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => _ArticleReader(
            article: article,
            isSaved: () => _saved.contains(article.id),
            onSave: () => _toggleSaved(article),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final browsing =
        _search.text.trim().isEmpty && _category == 'Tout' && !_favoritesOnly;
    final results = [featuredArticle, ...articlePreviews]
        .where(
          (a) =>
              (_category == 'Tout' || a.category == _category) &&
              (!_favoritesOnly || _saved.contains(a.id)) &&
              _normalize(
                '${a.title} ${a.category}',
              ).contains(_normalize(_search.text.trim())),
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              key: const PageStorageKey('articles-scroll'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                PageHeader(
                  title: 'Articles',
                  subtitle: 'Un peu de lecture. Beaucoup pour vous.',
                  showBack: widget.showBack,
                  action: SizedBox(
                    width: 48,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _favoritesOnly
                            ? AppColors.primaryLighter
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IconButton(
                        tooltip: 'Mes favoris',
                        isSelected: _favoritesOnly,
                        onPressed: () =>
                            setState(() => _favoritesOnly = !_favoritesOnly),
                        icon: Badge(
                          isLabelVisible: _saved.isNotEmpty,
                          label: Text('${_saved.length}'),
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            _favoritesOnly
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: AppDecor.t(13),
                  decoration: InputDecoration(
                    hintText: 'Un sujet, une question…',
                    hintStyle: AppDecor.t(13, c: AppColors.textMuted),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                    ),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Effacer la recherche',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() => _search.clear()),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final category in [
                        'Tout',
                        'Diabète',
                        'Hypertension',
                        'Bien-être',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: category == _category,
                            onSelected: (_) =>
                                setState(() => _category = category),
                            showCheckmark: false,
                            labelStyle: AppDecor.t(
                              12,
                              w: FontWeight.w600,
                              c: category == _category
                                  ? Colors.white
                                  : AppColors.textMuted,
                            ),
                            selectedColor: _editorialBlue,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: category == _category
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 24),
                if (browsing) ...[
                  _sectionTitle('À la une', 'Votre pause lecture'),
                  const SizedBox(height: 14),
                  _featured(),
                  for (final collection in [
                    'Comprendre votre santé',
                    'Prendre soin de soi',
                    'Les petits gestes qui comptent',
                  ]) ...[
                    const SizedBox(height: 28),
                    _sectionTitle(
                      collection,
                      collection == 'Comprendre votre santé'
                          ? 'Des repères, tout simplement'
                          : collection == 'Prendre soin de soi'
                          ? 'Du temps pour ce qui compte'
                          : 'À votre rythme',
                    ),
                    const SizedBox(height: 14),
                    _collectionRail(collection),
                  ],
                ] else ...[
                  _sectionTitle(
                    _favoritesOnly ? 'Mes favoris' : 'Votre sélection',
                    '${results.length} ${results.length == 1 ? 'article disponible' : 'articles disponibles'}',
                  ),
                  const SizedBox(height: 16),
                  if (results.isEmpty)
                    _empty()
                  else
                    for (final article in results)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ArticleCard(
                          article: article,
                          saved: _saved.contains(article.id),
                          onOpen: () => _openArticle(article),
                          onSave: () => _toggleSaved(article),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppDecor.t(
          19,
          w: FontWeight.w700,
          h: 1.3,
        ).copyWith(letterSpacing: -.4),
      ),
      const SizedBox(height: 5),
      Text(subtitle, style: AppDecor.t(11, c: AppColors.textMuted)),
    ],
  );

  Widget _featured() => Material(
    color: featuredArticle.background,
    borderRadius: BorderRadius.circular(26),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _openArticle(featuredArticle),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'POUR MIEUX SE CONNAÎTRE',
                    style: AppDecor.t(
                      10,
                      w: FontWeight.w700,
                      c: AppColors.primaryAccent,
                    ).copyWith(letterSpacing: 1),
                  ),
                ),
                _SaveButton(
                  saved: _saved.contains(featuredArticle.id),
                  onPressed: () => _toggleSaved(featuredArticle),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) {
                final title = Text(
                  featuredArticle.title,
                  style: AppDecor.t(
                    21,
                    w: FontWeight.w700,
                    h: 1.35,
                  ).copyWith(letterSpacing: -.6),
                );
                final art = SizedBox(
                  height: 132,
                  width: 112,
                  child: ArticleCover(article: featuredArticle),
                );
                if (constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(14) > 18) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: art),
                      const SizedBox(height: 12),
                      title,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 8),
                    art,
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Des sujets essentiels, à explorer à votre rythme.',
              style: AppDecor.t(12, c: const Color(0xFF42718C)),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    ),
  );

  Widget _collectionRail(String collection) {
    final articles = articlePreviews
        .where((a) => a.collection == collection)
        .toList();
    double textHeight(String text, TextStyle style, {int? maxLines}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: maxLines,
        ellipsis: maxLines == null ? null : '…',
      )..layout(maxWidth: 184);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final height = articles
        .map(
          (a) =>
              194.0 +
              textHeight(
                a.category.toUpperCase(),
                AppDecor.t(9, w: FontWeight.w700).copyWith(letterSpacing: 1),
              ) +
              textHeight(
                a.title,
                AppDecor.t(15, w: FontWeight.w600, h: 1.35),
                maxLines: 3,
              ),
        )
        .fold<double>(0, (largest, next) => next > largest ? next : largest);
    return SizedBox(
      height: height.ceilToDouble() + 2,
      child: ListView.separated(
        key: PageStorageKey('article-collection-$collection'),
        scrollDirection: Axis.horizontal,
        itemCount: articles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, index) {
          final article = articles[index];
          return SizedBox(
            width: 216,
            child: _ArticleCard(
              article: article,
              saved: _saved.contains(article.id),
              onOpen: () => _openArticle(article),
              onSave: () => _toggleSaved(article),
            ),
          );
        },
      ),
    );
  }

  Widget _empty() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Icon(
          _favoritesOnly ? Icons.bookmarks_outlined : Icons.search_off_rounded,
          size: 38,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          _favoritesOnly && _search.text.isEmpty && _category == 'Tout'
              ? 'Votre bibliothèque commence ici'
              : 'Aucun article trouvé',
          textAlign: TextAlign.center,
          style: AppDecor.t(17, w: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          _favoritesOnly
          ? 'Enregistrez vos articles préférés avec le marque-page, ou explorez un autre thème.'
              : 'Essayez un autre mot ou un autre thème.',
          textAlign: TextAlign.center,
          style: AppDecor.t(12, c: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _reset,
          child: const Text('Réinitialiser la recherche'),
        ),
      ],
    ),
  );
}

class _SaveButton extends StatelessWidget {
  final bool saved;
  final VoidCallback onPressed;
  final bool header;
  const _SaveButton({
    required this.saved,
    required this.onPressed,
    this.header = false,
  });
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: saved ? 'Retirer des favoris' : 'Enregistrer cet article',
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: .9),
      minimumSize: header ? const Size(48, 48) : null,
      shape: header
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
          : null,
      side: header ? const BorderSide(color: AppColors.border) : null,
    ),
    icon: Icon(
      saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      color: AppColors.primary,
      size: 21,
    ),
  );
}

class _ArticleCard extends StatelessWidget {
  final ArticlePreview article;
  final bool saved;
  final VoidCallback onOpen, onSave;
  const _ArticleCard({
    required this.article,
    required this.saved,
    required this.onOpen,
    required this.onSave,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(23),
      side: BorderSide(color: AppColors.border.withValues(alpha: .65)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 148,
            child: Stack(
              children: [
                Positioned.fill(child: ArticleCover(article: article)),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _SaveButton(saved: saved, onPressed: onSave),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.category.toUpperCase(),
                  style: AppDecor.t(
                    9,
                    w: FontWeight.w700,
                    c: article.textAccent,
                  ).copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  article.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppDecor.t(15, w: FontWeight.w600, h: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ArticleReader extends StatefulWidget {
  final ArticlePreview article;
  final bool Function() isSaved;
  final Future<void> Function() onSave;
  const _ArticleReader({
    required this.article,
    required this.isSaved,
    required this.onSave,
  });
  @override
  State<_ArticleReader> createState() => _ArticleReaderState();
}

class _ArticleReaderState extends State<_ArticleReader> {
  bool _saving = false;
  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                PageHeader(
                  title: 'Article',
                  action: _SaveButton(
                    header: true,
                    saved: widget.isSaved(),
                    onPressed: () async {
                      if (_saving) return;
                      _saving = true;
                      await widget.onSave();
                      if (mounted) setState(() => _saving = false);
                    },
                  ),
                ),
                const SizedBox(height: 26),
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: SizedBox(
                    height: 220,
                    child: ArticleCover(article: article),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  article.category.toUpperCase(),
                  style: AppDecor.t(
                    11,
                    w: FontWeight.w700,
                    c: article.textAccent,
                  ).copyWith(letterSpacing: 1.5),
                ),
                const SizedBox(height: 10),
                Text(
                  article.title,
                  style: AppDecor.t(27, w: FontWeight.w700, h: 1.3),
                ),
                const SizedBox(height: 24),
                Text(article.introduction, style: AppDecor.t(15, h: 1.8)),
                const SizedBox(height: 28),
                for (final section in article.sections) ...[
                  Text(
                    section.title,
                    style: AppDecor.t(18, w: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(section.body, style: AppDecor.t(14, h: 1.75)),
                  const SizedBox(height: 22),
                ],
                if (article.sources.isNotEmpty) ...[
                  Text('Sources', style: AppDecor.t(17, w: FontWeight.w700)),
                  const SizedBox(height: 8),
                  for (final source in article.sources)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: InkWell(
                        onTap: () => launchUrl(
                          Uri.parse(source.url),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                source.title,
                                style: AppDecor.t(
                                  12,
                                  c: AppColors.primary,
                                ).copyWith(decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> openArticlesPage(BuildContext context) async {
  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => const ArticlesPage(),
    ),
  );
}
