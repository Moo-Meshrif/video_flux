/// The lifecycle status of a controller retained by `VideoFlux`.
enum VideoFluxStatus {
  /// The backend controller is being initialized.
  initializing,

  /// The backend controller initialized successfully.
  ready,

  /// The backend controller could not be initialized.
  failed,

  /// The backend controller has been released.
  disposed,
}
