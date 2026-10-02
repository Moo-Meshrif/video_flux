// The whole public API. Import only this file:
//
//   import 'package:video_flux/video_flux.dart';
//
// Everything under `src/` is implementation detail.

// The preloader.
export 'src/video_flux.dart';
export 'src/video_flux_typedefs.dart';

// Your player adapter and item model.
export 'src/video_controller.dart';
export 'src/models/video_flux_item.dart';

// Configuration.
export 'src/models/video_flux_config.dart';
export 'src/models/retry_policy.dart';
export 'src/models/device_tier_probe.dart';
export 'src/enums/device_tier.dart';
export 'src/enums/memory_pressure_level.dart';

// Observing the preloader.
export 'src/models/video_flux_state.dart';
export 'src/models/video_flux_event.dart';
export 'src/models/video_flux_limits.dart';
export 'src/models/video_flux_stats.dart' show VideoFluxStats;
export 'src/enums/video_flux_status.dart';
export 'src/enums/video_flux_direction.dart';

// Optional: a bounded cache of last frames, for showing while a video
// initializes again.
export 'src/poster_cache.dart';
