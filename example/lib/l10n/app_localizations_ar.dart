import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Video Flux';

  @override
  String get editContent => 'تعديل المحتوى';

  @override
  String get editConfiguration => 'تعديل الإعدادات';

  @override
  String resetStyle(String style) {
    return 'إعادة تعيين $style إلى الإعدادات الافتراضية';
  }

  @override
  String get debugPanel => 'لوحة الاحصائيات';

  @override
  String get closeDebugPanel => 'إغلاق لوحة الاحصائيات';

  @override
  String get switchLanguage => 'تبديل اللغة';

  @override
  String get close => 'إغلاق';

  @override
  String get styleFacebook => 'فيسبوك';

  @override
  String get styleTikTok => 'تيك توك';

  @override
  String get styleShorts => 'Shorts';

  @override
  String get styleStories => 'القصص';

  @override
  String get styleFacebookTitle => 'فيسبوك';

  @override
  String get styleTikTokTitle => 'تيك توك';

  @override
  String get styleShortsTitle => 'Shorts';

  @override
  String get styleStoriesTitle => 'القصص';

  @override
  String get styleFacebookSummary => 'منشورات فيديو بين المنشورات النصية في قائمة قابلة للتمرير. يتم تحميل الفيديوهات مسبقًا، فيديو واحد إلى الأمام.';

  @override
  String get styleTikTokSummary => 'صفحات عمودية بملء الشاشة، فيديو واحد في كل صفحة. يتم الاحتفاظ بفيديو واحد خلف الصفحة الحالية وفيديوهين أمامها.';

  @override
  String get styleShortsSummary => 'نفس الشكل، مع الاحتفاظ أيضًا بفيديوهين خلف الصفحة الحالية لأن المستخدمين قد يعودون للخلف أثناء التمرير.';

  @override
  String get styleStoriesSummary => 'تمرير أفقي بالنقر للانتقال، وينتقل تلقائيًا عند انتهاء المقطع. يتم تجهيز المقطع التالي فقط.';

  @override
  String get couldNotLoadFeed => 'تعذر تحميل الموجز.';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String clipCaption(int number, int total) {
    return 'المقطع $number من $total';
  }

  @override
  String videoNumber(int number) {
    return 'الفيديو $number';
  }

  @override
  String authorName(int number) {
    return 'المؤلف $number';
  }

  @override
  String positionOfTotal(int position, int total) {
    return '$position / $total';
  }

  @override
  String get outsideWindow => 'خارج نطاق التحميل المسبق — لم يتم تحميله';

  @override
  String initializingAttempt(int attempt) {
    return 'جارٍ التهيئة (المحاولة $attempt)…';
  }

  @override
  String couldNotLoadVideo(String error) {
    return 'تعذر تحميل هذا الفيديو\n$error';
  }

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get like => 'إعجاب';

  @override
  String get comment => 'تعليق';

  @override
  String get share => 'مشاركة';

  @override
  String commentsAndShares(int comments, int shares) {
    return '$comments تعليق · $shares مشاركة';
  }

  @override
  String get sampleCommenter => 'سارة';

  @override
  String get sampleComment => 'سلس! لا يوجد أي تقطع عند التمرير.';

  @override
  String contentTitle(String style) {
    return 'محتوى $style';
  }

  @override
  String configTitle(String style) {
    return 'إعدادات $style';
  }

  @override
  String get savingRestartsFeed => 'سيؤدي الحفظ إلى إعادة تشغيل الموجز.';

  @override
  String get applyingRestartsFeed => 'سيؤدي التطبيق إلى إعادة تشغيل الموجز.';

  @override
  String get videoUrlsLabel => 'عناوين URL للفيديو، واحد في كل سطر';

  @override
  String playableSummary(int valid) {
    return '$valid قابل للتشغيل';
  }

  @override
  String playableSummarySkipped(int valid, int skipped) {
    return '$valid قابل للتشغيل، تم تخطي $skipped (ليس http/https)';
  }

  @override
  String get addBrokenUrl => 'إضافة عنوان URL معطّل';

  @override
  String get resetToSamples => 'إعادة التعيين إلى العينات';

  @override
  String get textPostsLabel => 'المنشورات النصية، واحد في كل سطر';

  @override
  String get textPostBeforeEvery => 'منشور نصي قبل كل';

  @override
  String get nthVideo => 'فيديو رقم';

  @override
  String get videosPerPage => 'فيديوهات لكل صفحة';

  @override
  String get repeatTheList => 'تكرار القائمة';

  @override
  String get repeatHint => 'بعد هذا العدد من مرات التكرار ينتهي الموجز.';

  @override
  String repeatCount(int count) {
    return '$count×';
  }

  @override
  String feedHoldsTotal(int count) {
    return 'يحتوي الموجز على $count فيديو إجمالًا.';
  }

  @override
  String get save => 'حفظ';

  @override
  String get apply => 'تطبيق';

  @override
  String get resetToPreset => 'إعادة التعيين إلى الإعداد المسبق';

  @override
  String decreaseField(String label) {
    return 'تقليل $label';
  }

  @override
  String increaseField(String label) {
    return 'زيادة $label';
  }

  @override
  String get sectionWindow => 'النطاق';

  @override
  String get sectionFastScrolling => 'التمرير السريع';

  @override
  String get sectionPagination => 'التصفح بالصفحات';

  @override
  String get sectionMemory => 'الذاكرة';

  @override
  String get sectionFailures => 'الأخطاء';

  @override
  String get fieldBehind => 'خلف';

  @override
  String get fieldAhead => 'أمام';

  @override
  String get fieldWindowSize => 'حجم النطاق';

  @override
  String get fieldWindowSizeHint => 'يجب أن يتجاوز مجموع الخلف والأمام.';

  @override
  String get fieldDirectionBias => 'تحيز الاتجاه';

  @override
  String get fieldDirectionBiasHint => 'عناصر إضافية في اتجاه التمرير.';

  @override
  String get fieldVelocityPreload => 'التحميل المسبق حسب السرعة';

  @override
  String get fieldVelocityPreloadHint => 'عناصر إضافية للتمرير السريع (يتطلب توفر سرعة).';

  @override
  String get fieldConcurrentInits => 'عمليات التهيئة المتزامنة';

  @override
  String get unlimited => 'غير محدود';

  @override
  String get fieldScrollDebounce => 'تأخير التمرير';

  @override
  String millisecondsValue(int value) {
    return '$value مللي ثانية';
  }

  @override
  String get fieldJumpThreshold => 'حد القفز';

  @override
  String get fieldJumpThresholdHint => 'حركة بهذا الحجم تتجاوز فترة التأخير.';

  @override
  String get fieldPaginationThreshold => 'حد التصفح بالصفحات';

  @override
  String get fieldPaginationThresholdHint => 'تحميل المزيد عند بقاء هذا العدد القليل من العناصر.';

  @override
  String get fieldAdaptive => 'متكيف';

  @override
  String get fieldAdaptiveHint => 'تضييق النطاق حسب فئة الجهاز وضغط الذاكرة.';

  @override
  String get fieldDeviceTier => 'فئة الجهاز';

  @override
  String get fieldRetryPolicy => 'سياسة إعادة المحاولة';

  @override
  String get tierAuto => 'اكتشاف تلقائي';

  @override
  String get tierLow => 'فرض منخفض';

  @override
  String get tierMid => 'فرض متوسط';

  @override
  String get tierHigh => 'فرض مرتفع';

  @override
  String get retryExponential => 'أسي، محاولة إعادة واحدة';

  @override
  String get retryExponentialThree => 'أسي، 3 محاولات إعادة';

  @override
  String get retryFixed => 'تأخير ثابت، محاولتا إعادة';

  @override
  String get retryNone => 'بدون إعادة محاولة';

  @override
  String get tabStats => 'الإحصاءات';

  @override
  String get tabWindow => 'النطاق';

  @override
  String get tabEvents => 'الأحداث';

  @override
  String get tabControls => 'عناصر التحكم';

  @override
  String eventsCount(int count) {
    return '$count حدث';
  }

  @override
  String get clear => 'مسح';

  @override
  String get legendNotLoaded => 'لم يتم التحميل';

  @override
  String get legendInitializing => 'جارٍ التهيئة';

  @override
  String get legendReady => 'جاهز';

  @override
  String get legendFailed => 'فشل';

  @override
  String get firstRetainedIndex => 'فهرس أول عنصر محتفظ به';

  @override
  String get activeIndex => 'الفهرس النشط';

  @override
  String get direction => 'الاتجاه';

  @override
  String get videosLoaded => 'الفيديوهات المحملة';

  @override
  String get rowsLoaded => 'الصفوف المحملة';

  @override
  String get tapCellToJump => 'اضغط على خلية للانتقال إليها.';

  @override
  String get statsWindow => 'النطاق';

  @override
  String get statsWork => 'العمل';

  @override
  String get statsScrolling => 'التمرير';

  @override
  String get statsEnvironment => 'البيئة';

  @override
  String get statsEnforced => 'المطبق مقابل المكوّن';

  @override
  String get statRetainedWindow => 'النطاق المحتفظ به / حجم النطاق';

  @override
  String get statReady => 'جاهز';

  @override
  String get statInitializing => 'جارٍ التهيئة';

  @override
  String get statFailed => 'فشل';

  @override
  String get statQueued => 'في قائمة الانتظار للحصول على فتحة';

  @override
  String get statInitsStarted => 'عمليات التهيئة التي بدأت';

  @override
  String get statSucceeded => 'نجحت';

  @override
  String get statFailedAttempts => 'المحاولات الفاشلة';

  @override
  String get statRetried => 'أُعيدت المحاولة';

  @override
  String get statDropped => 'تم إسقاطها قبل البدء';

  @override
  String get statReleased => 'وحدات التحكم التي تم تحريرها';

  @override
  String get statScrolls => 'عمليات التمرير التي تم تنفيذها';

  @override
  String get statPoolHit => 'معدل نجاح الاستفادة من التجمع';

  @override
  String get statAvgInit => 'متوسط التهيئة';

  @override
  String get statP95Init => 'تهيئة P95';

  @override
  String get statDeviceTier => 'فئة الجهاز';

  @override
  String get statMemoryPressure => 'ضغط الذاكرة';

  @override
  String get statPagination => 'التصفح بالصفحات';

  @override
  String get paginationReachedEnd => 'تم الوصول إلى النهاية';

  @override
  String get paginationMoreAvailable => 'المزيد متاح';

  @override
  String get statBehindAhead => 'خلف / أمام';

  @override
  String get statWindow => 'النطاق';

  @override
  String get statConcurrentInits => 'عمليات التهيئة المتزامنة';

  @override
  String withConfig(String value, String config) {
    return '$value   (الإعداد $config)';
  }

  @override
  String get controlsMemoryPressure => 'ضغط الذاكرة';

  @override
  String get memoryPressureHint => 'يتم تقليص النطاق فورًا. يؤدي اختيار مستوى أقل حدة إلى توسيع النطاق مجددًا مستوى واحدًا في كل مرة.';

  @override
  String get pressureNone => 'لا يوجد';

  @override
  String get pressureModerate => 'متوسط';

  @override
  String get pressureCritical => 'حرج';

  @override
  String get controlsScrolling => 'التمرير';

  @override
  String get flickForward => 'تمرير سريع ×10 للأمام';

  @override
  String get flickBack => 'تمرير سريع ×10 للخلف';

  @override
  String get jumpFirst => 'الانتقال إلى الأول';

  @override
  String get jumpMiddle => 'الانتقال إلى المنتصف';

  @override
  String get jumpLast => 'الانتقال إلى آخر فيديو محمّل';

  @override
  String get flickHint => 'التمرير السريع ينتقل فيديو واحدًا كل 40 مللي ثانية: راقب كيف يجمع التأخير عمليات التمرير، وكيف يرتفع عدد العناصر التي تم إسقاطها قبل البدء.';

  @override
  String get controlsFailures => 'الأخطاء';

  @override
  String get failNextPage => 'إفشال طلب الصفحة التالية';

  @override
  String get failNextPageHint => 'لاختبار التراجع التدريجي عند إعادة محاولة التصفح بالصفحات.';

  @override
  String get retryAllFailed => 'إعادة محاولة جميع الفيديوهات الفاشلة';

  @override
  String get failuresHint => 'أضف عنوان URL معطّلًا في «تعديل المحتوى» لرؤية عمليات إعادة المحاولة وحالات الفشل.';

  @override
  String get settings => 'الإعدادات';
}
