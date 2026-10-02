import 'package:video_flux/video_flux.dart';

/// One row of a feed.
sealed class FeedPost {
  const FeedPost({required this.id});

  /// Durable identity, unique within one feed.
  final String id;
}

/// A post carrying a video; the only style `VideoFlux` ever sees.
final class VideoPost extends FeedPost implements VideoFluxItem {
  /// Creates a video post.
  const VideoPost({
    required super.id,
    required this.url,
    required this.number,
    this.thumbnailUrl,
  });

  @override
  final String url;

  /// A still of the video, shown while it loads when no frame of it has been
  /// captured yet, such as one the user flicked past before ever watching it.
  final String? thumbnailUrl;

  /// One-based position of the video in the feed.
  final int number;
}

/// A post with no video, which the preloader never counts or loads.
final class TextPost extends FeedPost {
  /// Creates a text post.
  const TextPost({
    required super.id,
    required this.authorNumber,
    required this.body,
  });

  /// Which of the sample authors posted this, starting at 1.
  final int authorNumber;

  /// The post text.
  final String body;
}
