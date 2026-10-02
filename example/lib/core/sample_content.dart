/// Publicly hosted clips used until the user supplies their own.
///
/// Every URL is distinct and serves an MP4 whose `moov` atom precedes the
/// media data, so the player can initialize after the first few kilobytes
/// instead of downloading the whole file.
const List<String> sampleVideoUrls = <String>[
  'https://storage.googleapis.com/cloud-samples-data/generative-ai/'
      'video/describe_video_content.mp4',
  'https://storage.googleapis.com/cloud-samples-data/generative-ai/'
      'video/ad_copy_from_video.mp4',
  'https://storage.googleapis.com/cloud-samples-data/video/cat.mp4',
  'https://www.w3schools.com/html/movie.mp4',
  'https://static.videezy.com/system/resources/previews/000/000/168/'
      'original/Record.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
  'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
  'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/'
      'Big_Buck_Bunny_360_10s_1MB.mp4',
  'https://test-videos.co.uk/vids/jellyfish/mp4/h264/360/'
      'Jellyfish_360_10s_1MB.mp4',
  'https://test-videos.co.uk/vids/sintel/mp4/h264/360/'
      'Sintel_360_10s_1MB.mp4',
  'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/'
      'Big_Buck_Bunny_720_10s_1MB.mp4',
  'https://test-videos.co.uk/vids/jellyfish/mp4/h264/720/'
      'Jellyfish_720_10s_1MB.mp4',
  'https://test-videos.co.uk/vids/sintel/mp4/h264/720/'
      'Sintel_720_10s_1MB.mp4',
  'https://media.w3.org/2010/05/video/movie_300.mp4',
  'https://storage.googleapis.com/cloud-samples-data/video/animals.mp4',
  'https://vjs.zencdn.net/v/oceans.mp4',
  'https://storage.googleapis.com/cloud-samples-data/video/JaneGoodall.mp4',
];

/// Text posts interleaved between videos in the Facebook-style feed.
const List<String> sampleTextPosts = <String>[
  'Just shipped a feed that never runs out of memory. Turns out the trick is '
      'knowing what NOT to keep alive.',
  'Hot take: the best video is the one that is already decoded when you '
      'swipe to it.',
  'Reminder that a text post costs the preloader nothing — it only ever '
      'counts videos.',
  'Flicked past forty clips and only three decoders ever started. Good day.',
];

/// A URL that can never load, for exercising retries and failure states.
const String brokenVideoUrl = 'https://example.invalid/broken.mp4';
