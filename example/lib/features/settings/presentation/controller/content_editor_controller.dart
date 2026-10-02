import 'package:flutter/widgets.dart';

import '../../../../core/sample_content.dart';
import '../../../feed/data/models/feed_content.dart';
import '../../../feed/data/enums/feed_style.dart';
import '../../../feed/presentation/controller/feed_setup_controller.dart';

/// The state behind the content editor: what the user has typed so far.
///
/// Holds the text fields and the paging numbers, reports how many of the typed
/// URLs are playable, and turns the lot into a [FeedContent] on [save].
class ContentEditorController extends ChangeNotifier {
  /// Starts editing the content of [style].
  ContentEditorController({required this.style, required this.setups})
      : _initial = setups.setupOf(style).content {
    urls = TextEditingController(text: _initial.videoUrls.join('\n'))
      ..addListener(notifyListeners);
    texts = TextEditingController(text: _initial.textPosts.join('\n'));
    _pageSize = _initial.pageSize;
    _loops = _initial.loops;
    _textEvery = _initial.textEvery;
  }

  /// The feed style whose content is edited.
  final FeedStyle style;

  /// Where the feed style's setup lives.
  final FeedSetupController setups;

  final FeedContent _initial;

  /// The video URL field, one URL per line.
  late final TextEditingController urls;

  /// The text post field, one post per line.
  late final TextEditingController texts;

  late int _pageSize;
  late int _loops;
  late int _textEvery;

  /// Videos returned per page.
  int get pageSize => _pageSize;

  set pageSize(int value) {
    _pageSize = value;
    notifyListeners();
  }

  /// How many times the URL list repeats before the feed ends.
  int get loops => _loops;

  set loops(int value) {
    _loops = value;
    notifyListeners();
  }

  /// A text post appears before every Nth video.
  int get textEvery => _textEvery;

  set textEvery(int value) {
    _textEvery = value;
    notifyListeners();
  }

  List<String> get _lines => FeedContent.parseLines(urls.text);

  /// The typed URLs a player could open.
  List<String> get validUrls =>
      _lines.where(FeedContent.isPlayableUrl).toList(growable: false);

  /// How many typed lines are not playable URLs and will be skipped.
  int get invalidCount => _lines.length - validUrls.length;

  /// How many videos the feed will hold in total.
  int get totalVideos => validUrls.length * _loops;

  /// Whether there is anything to save.
  bool get canSave => validUrls.isNotEmpty;

  /// Appends a URL that can never load, to exercise retries and failures.
  void addBrokenUrl() {
    final String separator =
        urls.text.isEmpty || urls.text.endsWith('\n') ? '' : '\n';
    urls.text = '${urls.text}$separator$brokenVideoUrl';
  }

  /// Restores the starting content of the feed style.
  void resetToSamples() {
    final FeedContent defaults = style.defaultContent;
    urls.text = defaults.videoUrls.join('\n');
    texts.text = defaults.textPosts.join('\n');
    _pageSize = defaults.pageSize;
    _loops = defaults.loops;
    _textEvery = defaults.textEvery;
    notifyListeners();
  }

  /// Applies the edited content, which restarts the feed.
  void save() {
    final current = setups.setupOf(style);
    setups.update(
      style,
      current.copyWith(
        content: FeedContent(
          videoUrls: validUrls,
          textPosts: FeedContent.parseLines(texts.text),
          textEvery: _textEvery,
          pageSize: _pageSize,
          loops: _loops,
        ),
      ),
    );
  }

  @override
  void dispose() {
    urls.dispose();
    texts.dispose();
    super.dispose();
  }
}
