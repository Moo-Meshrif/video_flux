import 'dart:io' show Platform;

/// Returns the number of logical processors on this device.
int? readProcessorCount() => Platform.numberOfProcessors;
