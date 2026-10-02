import 'video_controller.dart';

/// Creates a controller for a single video source.
typedef VideoControllerFactory = CustomVideoController Function(String source);

/// Reports an error raised while a controller is initialized.
typedef ControllerInitializationError = void Function(
  CustomVideoController controller,
  Object error,
  StackTrace stackTrace,
);

/// Reports an error raised while loading the next page of items.
typedef PaginationError = void Function(Object error, StackTrace stackTrace);
