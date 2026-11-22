// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'لينك تو شات';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get startupDataErrorMessage => 'تعذر فتح البيانات المحلية.';

  @override
  String get startupResetAction => 'إعادة ضبط البيانات المحلية';

  @override
  String get startupResetConfirmTitle => 'إعادة ضبط البيانات المحلية؟';

  @override
  String get startupResetConfirmMessage =>
      'سيتم حذف كل ما هو محفوظ على هذا الجهاز (السجل والإحصائيات والحسابات). لا يمكن التراجع عن ذلك.';

  @override
  String get startupResetConfirmAction => 'حذف وإعادة التشغيل';

  @override
  String get errorGeneric => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get errorAuth => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get errorStorage => 'تعذر الحفظ على هذا الجهاز.';

  @override
  String get commonLoading => 'جارٍ التحميل...';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonCreate => 'إنشاء';

  @override
  String get commonOk => 'موافق';

  @override
  String get commonUnknown => 'غير معروف';

  @override
  String commonErrorPrefix(String error) {
    return 'خطأ: $error';
  }

  @override
  String get commonUserNotAuthenticated => 'المستخدم غير مصادق عليه';

  @override
  String get commonWhatsApp => 'WhatsApp';

  @override
  String get commonTelegram => 'Telegram';

  @override
  String get commonHome => 'الرئيسية';

  @override
  String get commonDashboard => 'لوحة التحكم';

  @override
  String get commonHistory => 'السجل';

  @override
  String get commonTeams => 'الفرق';

  @override
  String get commonSettings => 'الإعدادات';

  @override
  String get commonLinkCopied => 'تم نسخ الرابط إلى الحافظة';

  @override
  String get commonCopyLink => 'نسخ الرابط';

  @override
  String get commonYes => 'نعم';

  @override
  String get commonNo => 'لا';

  @override
  String get commonCreated => 'تم الإنشاء';

  @override
  String get commonPermissions => 'الأذونات';

  @override
  String get commonDescriptionOptional => 'الوصف (اختياري)';

  @override
  String get commonViewHistory => 'عرض السجل';

  @override
  String get commonReady => 'جاهز';

  @override
  String get commonNever => 'أبدًا';

  @override
  String get commonInitializing => 'جارٍ التهيئة...';

  @override
  String commonPlatformLink(String platformName) {
    return 'رابط $platformName';
  }

  @override
  String get splashTagline => 'حوّل أرقام الهواتف إلى روابط محادثة فورًا';

  @override
  String get homeTitle => 'تحويل أرقام الهواتف إلى روابط محادثة';

  @override
  String get homeSubtitle =>
      'أدخل رقم هاتف لإنشاء روابط محادثة فورية لـ WhatsApp و Telegram';

  @override
  String get homeGenerateQr => 'إنشاء رمز QR';

  @override
  String homeQrTitle(String platformName) {
    return 'رمز QR لـ $platformName';
  }

  @override
  String get homeLoading => 'جارٍ إنشاء الرابط...';

  @override
  String get homePhoneLabel => 'رقم الهاتف';

  @override
  String get homePhoneHint => 'أدخل رقم الهاتف';

  @override
  String get homePasteTooltip => 'لصق رقم الهاتف';

  @override
  String get homePasteButton => 'لصق الرقم الكامل';

  @override
  String homeResultTitle(String platformName) {
    return 'رابط $platformName الخاص بك';
  }

  @override
  String get homeCopyTooltip => 'نسخ الرابط';

  @override
  String get homeActionQr => 'رمز QR';

  @override
  String get homeActionShare => 'مشاركة';

  @override
  String get homeActionOpen => 'فتح';

  @override
  String get homeQrShare => 'مشاركة رمز QR';

  @override
  String homeQrShareTitle(String title) {
    return 'مشاركة رمز QR لـ $title';
  }

  @override
  String get homeInvalidNumber => 'يرجى إدخال رقم هاتف صالح';

  @override
  String homeErrorGenerating(String error) {
    return 'خطأ في إنشاء الرابط: $error';
  }

  @override
  String get homeGuestLimit =>
      'يمكن للمستخدمين الضيوف إنشاء رابطين فقط. يرجى التسجيل أو تسجيل الدخول للمتابعة.';

  @override
  String get dashboardLoading => 'جارٍ تحميل بيانات لوحة التحكم...';

  @override
  String get dashboardTotalLinks => 'إجمالي الروابط المنشأة';

  @override
  String get dashboardStatsTitle => 'إحصاءات المنصات';

  @override
  String get dashboardDistribution => 'توزيع المنصات';

  @override
  String dashboardLegendCount(num count) {
    return '($count)';
  }

  @override
  String get dashboardRecentActivity => 'النشاط الأخير';

  @override
  String get dashboardNoActivity => 'لا يوجد نشاط أخير';

  @override
  String get dashboardTopCountries => 'أعلى الدول';

  @override
  String get dashboardNoData => 'لا توجد بيانات متاحة بعد';

  @override
  String dashboardError(String error) {
    return 'خطأ في تحميل بيانات لوحة التحكم: $error';
  }

  @override
  String get historyLoading => 'جارٍ تحميل السجل...';

  @override
  String get historyEmpty => 'لا يوجد سجل بعد';

  @override
  String get historyEmptyHint => 'ستظهر الروابط التي تنشئها هنا';

  @override
  String get historyDetailsPhone => 'رقم الهاتف:';

  @override
  String get historyDetailsCountry => 'الدولة:';

  @override
  String get historyDetailsGenerated => 'تاريخ الإنشاء:';

  @override
  String get historyDetailsLink => 'الرابط:';

  @override
  String get historyOpenLink => 'فتح الرابط';

  @override
  String get historyClearTitle => 'مسح السجل';

  @override
  String get historyClearMessage =>
      'هل أنت متأكد من أنك تريد مسح السجل بالكامل؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get historyClearConfirm => 'مسح';

  @override
  String historyErrorLoad(String error) {
    return 'فشل تحميل السجل: $error';
  }

  @override
  String historyErrorClear(String error) {
    return 'فشل مسح السجل: $error';
  }

  @override
  String get teamsLoading => 'جارٍ تحميل الفرق...';

  @override
  String get teamsEmpty => 'لا توجد فرق بعد';

  @override
  String get teamsEmptyHint => 'أنشئ فريقًا للتعاون مع الآخرين';

  @override
  String get teamsCreateTeam => 'إنشاء فريق';

  @override
  String get teamsYourTeams => 'فرقك';

  @override
  String get teamsUpgradeHint =>
      'قم بالترقية إلى خطة مميزة لإنشاء فرق والتعاون مع الآخرين';

  @override
  String get teamsEditTeam => 'تعديل الفريق';

  @override
  String get teamsDeleteTeam => 'حذف الفريق';

  @override
  String get teamsLoadingDetails => 'جارٍ تحميل تفاصيل الفريق...';

  @override
  String get teamsMembers => 'الأعضاء';

  @override
  String get teamsTabAnalytics => 'التحليلات';

  @override
  String teamsMembersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أعضاء',
      many: '$count عضوًا',
      few: '$count أعضاء',
      two: 'عضوان',
      one: 'عضو واحد',
      zero: 'لا أعضاء',
    );
    return '$_temp0';
  }

  @override
  String teamsCreated(String date) {
    return 'أُنشئ $date';
  }

  @override
  String get teamsOwner => 'المالك';

  @override
  String get teamsToday => 'اليوم';

  @override
  String get teamsYesterday => 'أمس';

  @override
  String teamsDaysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count يوم',
      many: 'قبل $count يومًا',
      few: 'قبل $count أيام',
      two: 'قبل يومين',
      one: 'قبل يوم',
    );
    return '$_temp0';
  }

  @override
  String teamsWeeksAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count أسبوع',
      many: 'قبل $count أسبوعًا',
      few: 'قبل $count أسابيع',
      two: 'قبل أسبوعين',
      one: 'قبل أسبوع',
    );
    return '$_temp0';
  }

  @override
  String teamsMonthsAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count شهر',
      many: 'قبل $count شهرًا',
      few: 'قبل $count أشهر',
      two: 'قبل شهرين',
      one: 'قبل شهر',
    );
    return '$_temp0';
  }

  @override
  String teamsYearsAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count سنة',
      many: 'قبل $count سنة',
      few: 'قبل $count سنوات',
      two: 'قبل سنتين',
      one: 'قبل سنة',
    );
    return '$_temp0';
  }

  @override
  String get teamsInviteMember => 'دعوة عضو';

  @override
  String get teamsAnalyticsComingSoon => 'تحليلات الفريق قريبًا';

  @override
  String get teamsSettingsTitle => 'إعدادات الفريق';

  @override
  String get teamsAllowInviteTitle => 'السماح للأعضاء بالدعوة';

  @override
  String get teamsAllowInviteSubtitle =>
      'اسمح للأعضاء ذوي دور المحرر أو أعلى بدعوة أعضاء جدد';

  @override
  String get teamsRequireApprovalTitle => 'اشتراط الموافقة على الروابط';

  @override
  String get teamsRequireApprovalSubtitle =>
      'ستتطلب الروابط التي ينشئها الأعضاء موافقة المشرف';

  @override
  String get teamsDangerZone => 'منطقة الخطر';

  @override
  String get teamsDeleteWarning =>
      'بمجرد حذف الفريق لا يمكن التراجع. يرجى التأكد من قرارك.';

  @override
  String get teamsDeleteThisTeam => 'حذف هذا الفريق';

  @override
  String get teamsDeleteConfirmMessage =>
      'هل أنت متأكد من أنك تريد حذف هذا الفريق؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get teamsInviteDialogPlaceholder =>
      'سيُنفَّذ مربع حوار دعوة العضو هنا';

  @override
  String get teamsCreateDialogTitle => 'إنشاء فريق';

  @override
  String get teamsNameLabel => 'اسم الفريق';

  @override
  String get teamsNameRequired => 'يرجى إدخال اسم الفريق';

  @override
  String get teamsCreateDialogHint =>
      'أنشئ فريقًا للتعاون مع الآخرين. يمكنك دعوة أعضاء الفريق بعد إنشاء الفريق.';

  @override
  String get teamsInviteTeamMember => 'دعوة عضو إلى الفريق';

  @override
  String get teamsEmailLabel => 'البريد الإلكتروني';

  @override
  String get teamsEmailHint => 'أدخل بريد العضو الإلكتروني';

  @override
  String get teamsEmailRequired => 'يرجى إدخال عنوان بريد إلكتروني';

  @override
  String get teamsEmailInvalid => 'يرجى إدخال عنوان بريد إلكتروني صالح';

  @override
  String get teamsMatchingUsers => 'المستخدمون المطابقون:';

  @override
  String get teamsSelectRole => 'اختر الدور:';

  @override
  String get teamsRolePermissions => 'أذونات الدور:';

  @override
  String get teamsRoleAdmin => 'مشرف';

  @override
  String get teamsRoleEditor => 'محرر';

  @override
  String get teamsRoleViewer => 'مشاهد';

  @override
  String get teamsInvite => 'دعوة';

  @override
  String get teamsRoleAdminDesc =>
      'يمكنه إدارة إعدادات الفريق والأعضاء وعرض جميع البيانات.';

  @override
  String get teamsRoleEditorDesc =>
      'يمكنه إنشاء الروابط وتعديلها، لكن لا يمكنه إدارة الفريق.';

  @override
  String get teamsRoleViewerDesc =>
      'يمكنه عرض بيانات الفريق فقط. لا يمكنه إنشاء الروابط أو تعديلها.';

  @override
  String get teamsInviteNoUser => 'لا يوجد مستخدم بهذا البريد الإلكتروني.';

  @override
  String get teamsInviteAlreadyMember => 'هذا المستخدم عضو في الفريق بالفعل.';

  @override
  String teamsInviteError(String error) {
    return 'خطأ في دعوة المستخدم: $error';
  }

  @override
  String get teamsUnknownUser => 'مستخدم غير معروف';

  @override
  String get teamsYouBadge => 'أنت';

  @override
  String get teamsRoleOwnerBadge => 'المالك';

  @override
  String get teamsRoleAdminBadge => 'مشرف';

  @override
  String get teamsRoleEditorBadge => 'محرر';

  @override
  String get teamsRoleViewerBadge => 'مشاهد';

  @override
  String get teamsMakeAdmin => 'تعيين كمشرف';

  @override
  String get teamsMakeEditor => 'تعيين كمحرر';

  @override
  String get teamsMakeViewer => 'تعيين كمشاهد';

  @override
  String get teamsRemoveFromTeam => 'إزالة من الفريق';

  @override
  String get teamsRemoveTitle => 'إزالة العضو';

  @override
  String teamsRemoveMessage(String memberName) {
    return 'هل أنت متأكد من أنك تريد إزالة $memberName من الفريق؟';
  }

  @override
  String get teamsRemove => 'إزالة';

  @override
  String teamsErrorLoad(String error) {
    return 'فشل تحميل الفرق: $error';
  }

  @override
  String get teamsErrorNotAllowed => 'اشتراكك لا يسمح بإنشاء فرق';

  @override
  String get teamsErrorCreate => 'فشل إنشاء الفريق';

  @override
  String teamsErrorCreateDetails(String error) {
    return 'فشل إنشاء الفريق: $error';
  }

  @override
  String get teamsErrorDelete => 'فشل حذف الفريق';

  @override
  String teamsErrorDeleteDetails(String error) {
    return 'فشل حذف الفريق: $error';
  }

  @override
  String get apiTitle => 'مفاتيح API';

  @override
  String get apiLoading => 'جارٍ تحميل مفاتيح API...';

  @override
  String get apiEmptyTitle => 'لا توجد مفاتيح API بعد';

  @override
  String get apiEmptyHint => 'أنشئ مفتاح API للتكامل مع الخدمات الخارجية';

  @override
  String get apiCreateKey => 'إنشاء مفتاح API';

  @override
  String get apiYourKeys => 'مفاتيح API الخاصة بك';

  @override
  String get apiKeysSubtitle =>
      'استخدم هذه المفاتيح للوصول إلى واجهة برمجة تطبيقات Link2Chat';

  @override
  String get apiDocsTitle => 'وثائق API';

  @override
  String get apiDocsBaseUrlHeading => 'العنوان الأساسي';

  @override
  String get apiDocsAuthHeading => 'المصادقة';

  @override
  String get apiDocsAuthBody =>
      'أضف مفتاح API الخاص بك إلى ترويسات الطلب:\nX-API-Key: your_api_key';

  @override
  String get apiDocsEndpointsHeading => 'نقاط النهاية';

  @override
  String get apiDocGetLinks => '• GET /links - عرض سجل روابطك';

  @override
  String get apiDocPostLinks => '• POST /links - إنشاء رابط جديد';

  @override
  String get apiDocGetAnalytics => '• GET /analytics - عرض إحصاءات الاستخدام';

  @override
  String get apiDocGetTeams => '• GET /teams - عرض قائمة فرقك';

  @override
  String get apiDocsPortal =>
      'للحصول على وثائق مفصلة، تفضل بزيارة بوابة المطورين لدينا.';

  @override
  String get apiLockedTitle => 'الوصول إلى API مقفل';

  @override
  String get apiLockedMessage =>
      'الوصول إلى API متاح في الخطة الاحترافية وخطة المؤسسات.';

  @override
  String get apiUpgradePlan => 'قم بترقية خطتك';

  @override
  String get apiKeyCreatedTitle => 'تم إنشاء مفتاح API';

  @override
  String get apiKeyCreatedWarning =>
      'انسخ هذا المفتاح الآن. لأسباب أمنية، لن تتمكن من رؤيته مرة أخرى.';

  @override
  String get apiCopyTooltip => 'نسخ إلى الحافظة';

  @override
  String get apiDeleteKeyTitle => 'حذف مفتاح API';

  @override
  String apiDeleteKeyMessage(String keyName) {
    return 'هل أنت متأكد من أنك تريد حذف مفتاح API \"$keyName\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get apiCopied => 'تم نسخ مفتاح API إلى الحافظة';

  @override
  String get apiKeyNameLabel => 'اسم المفتاح';

  @override
  String get apiKeyNameHint => 'مثال: تكامل تطبيق الجوال';

  @override
  String get apiKeyNameRequired => 'يرجى إدخال اسم لمفتاح API الخاص بك';

  @override
  String get apiKeyDescriptionHint => 'مثال: يُستخدم لتكامل تطبيق الجوال';

  @override
  String get apiKeySecurityNote => 'ملاحظة أمنية:';

  @override
  String get apiKeySecurityWarning =>
      'يوفر مفتاح API الخاص بك وصولاً إلى بيانات حسابك. لا تشارك مفاتيح API الخاصة بك أبدًا وامنح فقط الأذونات الضرورية لكل تكامل.';

  @override
  String get apiKeySelectPermission => 'يرجى اختيار إذن واحد على الأقل';

  @override
  String get apiKeyLabel => 'مفتاح API';

  @override
  String get apiLastUsed => 'آخر استخدام';

  @override
  String get apiPermissionGenerateLinks => 'إنشاء الروابط';

  @override
  String get apiPermissionGenerateLinksDesc =>
      'إنشاء روابط محادثة WhatsApp و Telegram';

  @override
  String get apiPermissionViewAnalytics => 'عرض التحليلات';

  @override
  String get apiPermissionViewAnalyticsDesc =>
      'الوصول إلى التحليلات والإحصاءات';

  @override
  String get apiPermissionViewHistoryDesc => 'عرض سجل إنشاء الروابط';

  @override
  String get apiPermissionExportData => 'تصدير البيانات';

  @override
  String get apiPermissionExportDataDesc => 'تصدير البيانات بصيغ متنوعة';

  @override
  String get apiPermissionViewTeamData => 'عرض بيانات الفريق';

  @override
  String get apiPermissionViewTeamDataDesc => 'عرض معلومات الفريق وأعضائه';

  @override
  String get apiPermissionManageTeam => 'إدارة الفريق';

  @override
  String get apiPermissionManageTeamDesc => 'إدارة إعدادات الفريق والأعضاء';

  @override
  String get authTagline => 'حوّل أرقام الهواتف إلى روابط محادثة';

  @override
  String get authLoggingIn => 'جارٍ تسجيل الدخول...';

  @override
  String get authEmailLabel => 'البريد الإلكتروني';

  @override
  String get authEmailRequired => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get authEmailInvalid => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get authPasswordLabel => 'كلمة المرور';

  @override
  String get authPasswordRequired => 'يرجى إدخال كلمة المرور';

  @override
  String get authPasswordTooShort =>
      'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get authLogin => 'تسجيل الدخول';

  @override
  String get authNoAccount => 'ليس لديك حساب؟ سجّل الآن';

  @override
  String get authContinueAsGuest => 'المتابعة كضيف';

  @override
  String get authInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get authRegisterTitle => 'إنشاء حساب';

  @override
  String get authCreatingAccount => 'جارٍ إنشاء الحساب...';

  @override
  String get authFullNameLabel => 'الاسم الكامل';

  @override
  String get authNameRequired => 'يرجى إدخال اسمك';

  @override
  String get authRegisterPasswordRequired => 'يرجى إدخال كلمة المرور';

  @override
  String get authConfirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get authConfirmPasswordRequired => 'يرجى تأكيد كلمة المرور';

  @override
  String get authPasswordsMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get authRegisterError =>
      'هذا البريد الإلكتروني مسجل بالفعل أو حدث خطأ آخر';

  @override
  String get settingsLoading => 'جارٍ تحميل الإعدادات...';

  @override
  String get settingsSectionAppearance => 'المظهر';

  @override
  String get settingsSectionBehavior => 'السلوك';

  @override
  String get settingsSaveHistoryTitle => 'حفظ سجل الروابط';

  @override
  String get settingsSaveHistorySubtitle =>
      'الاحتفاظ بسجل لجميع الروابط المنشأة';

  @override
  String get settingsShowQrTitle => 'إظهار رمز QR افتراضيًا';

  @override
  String get settingsShowQrSubtitle => 'عرض رمز QR عند إنشاء الرابط';

  @override
  String get settingsSectionAbout => 'حول التطبيق';

  @override
  String get settingsSectionSubscription => 'الاشتراك';

  @override
  String get settingsApiKeysSubtitle => 'إدارة مفاتيح API للتكامل';

  @override
  String get settingsSignOut => 'تسجيل الخروج';

  @override
  String get settingsSignOutConfirm => 'هل أنت متأكد من أنك تريد تسجيل الخروج؟';

  @override
  String get settingsSigningOut => 'جارٍ تسجيل الخروج...';

  @override
  String get settingsEnterPasswordTitle => 'أدخل كلمة المرور';

  @override
  String get settingsEnterPasswordMessage => 'يرجى إدخال كلمة المرور للمتابعة';

  @override
  String get settingsContinue => 'متابعة';

  @override
  String get settingsUpdatingAllData => 'جارٍ تحديث جميع البيانات المحلية...';

  @override
  String get settingsCancelled => 'أُلغي بواسطة المستخدم';

  @override
  String settingsLastLogin(String date) {
    return 'آخر تسجيل دخول: $date';
  }

  @override
  String get settingsRoleMember => 'عضو';

  @override
  String get settingsPermissionCreateLinks => 'إنشاء الروابط';

  @override
  String get settingsPermissionCreateTeams => 'إنشاء الفرق';

  @override
  String get settingsPermissionApiAccess => 'الوصول إلى API';

  @override
  String get settingsPermissionAdvancedAnalytics => 'تحليلات متقدمة';

  @override
  String get settingsPermissionAdminPanel => 'لوحة المشرف';

  @override
  String get settingsThemeTitle => 'وضع السمة';

  @override
  String get settingsThemeSystem => 'النظام';

  @override
  String get settingsThemeSystemSubtitle => 'اتباع إعدادات النظام';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeLightSubtitle => 'سمة فاتحة للاستخدام النهاري';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsThemeDarkSubtitle => 'سمة داكنة للاستخدام الليلي';

  @override
  String get settingsDefaultPlatform => 'المنصة الافتراضية';

  @override
  String get settingsDefaultBadge => 'افتراضية';

  @override
  String get settingsComingSoon => 'هذه الميزة قادمة قريبًا!';

  @override
  String get settingsEditProfile => 'تعديل الملف الشخصي';

  @override
  String get settingsNameLabel => 'الاسم';

  @override
  String get settingsNewPasswordLabel =>
      'كلمة مرور جديدة (اتركها فارغة للإبقاء على الحالية)';

  @override
  String get settingsUpdateFailed =>
      'فشل التحديث. قد يكون البريد الإلكتروني مستخدمًا بالفعل.';

  @override
  String get settingsSave => 'حفظ';

  @override
  String get settingsProfileUpdated => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get settingsPlanTitle => 'خطة الاشتراك';

  @override
  String get settingsPremiumNoTeams =>
      'لديك اشتراك مميز لكنك لم تنشئ أي فرق بعد';

  @override
  String get settingsTeamsBenefit =>
      'تتيح لك الفرق التعاون مع الآخرين ومشاركة الروابط';

  @override
  String get settingsCreateFirstTeam => 'أنشئ فريقك الأول';

  @override
  String get settingsSectionAccount => 'الحساب';

  @override
  String get settingsGuestUser => 'مستخدم ضيف';

  @override
  String get settingsGuestUsingApp => 'أنت تستخدم التطبيق حاليًا كضيف';

  @override
  String get settingsLimitedFeatures => 'ميزات محدودة';

  @override
  String get settingsGuestSignInPrompt =>
      'سجّل الدخول أو أنشئ حسابًا للوصول إلى جميع الميزات:';

  @override
  String get settingsSignIn => 'تسجيل الدخول';

  @override
  String get settingsSignUp => 'إنشاء حساب';

  @override
  String get settingsFeatureSaveHistory => 'حفظ سجل روابطك';

  @override
  String get settingsFeatureSyncDevices => 'المزامنة عبر الأجهزة';

  @override
  String get settingsFeatureTeams => 'إنشاء فرق ومشاركة الروابط';

  @override
  String get settingsFeatureAnalytics => 'الوصول إلى التحليلات المتقدمة';

  @override
  String get settingsFeatureApi => 'استخدام API للتكاملات';

  @override
  String get settingsDeleteAccount => 'حذف الحساب';

  @override
  String get settingsDeleteAccountWarning =>
      'تحذير: لا يمكن التراجع عن هذا الإجراء. سيتم حذف جميع بياناتك نهائيًا.';

  @override
  String get settingsDeleteAccountPrompt =>
      'يرجى إدخال كلمة المرور لتأكيد الحذف:';

  @override
  String get settingsAccountDeleted => 'تم حذف الحساب بنجاح';

  @override
  String get settingsIncorrectPassword => 'كلمة المرور غير صحيحة';

  @override
  String get settingsAdminEmailLabel => 'بريد المشرف الإلكتروني';

  @override
  String get settingsAdminEmailRequired => 'يرجى إدخال بريد المشرف الإلكتروني';

  @override
  String get settingsAdminPasswordLabel => 'كلمة مرور المشرف';

  @override
  String get settingsAdminPasswordRequired => 'يرجى إدخال كلمة مرور المشرف';

  @override
  String get settingsVersion => 'الإصدار';

  @override
  String get settingsPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get settingsPrivacyPolicySubtitle => 'اقرأ سياسة الخصوصية لدينا';

  @override
  String get settingsTermsOfService => 'شروط الخدمة';

  @override
  String get settingsTermsSubtitle => 'اقرأ شروط الخدمة لدينا';

  @override
  String get subscriptionTitle => 'خطط الاشتراك';

  @override
  String get subscriptionChoosePlan => 'اختر خطة';

  @override
  String get subscriptionTierFree => 'مجانية';

  @override
  String get subscriptionTierBasic => 'أساسية';

  @override
  String get subscriptionTierProfessional => 'احترافية';

  @override
  String get subscriptionTierEnterprise => 'مؤسسية';

  @override
  String get subscriptionPriceFree => '\$0';

  @override
  String get subscriptionPriceBasic => '\$4.99';

  @override
  String get subscriptionPriceProfessional => '\$9.99';

  @override
  String get subscriptionPriceEnterprise => '\$29.99';

  @override
  String get subscriptionForever => 'للأبد';

  @override
  String get subscriptionPerMonth => 'شهريًا';

  @override
  String get subscriptionFreeFeature1 => 'إنشاء الروابط الأساسي';

  @override
  String subscriptionFreeFeatureHistory(num count) {
    return 'سجل محدود ($count عنصر)';
  }

  @override
  String get subscriptionFreeFeatureAnalytics => 'تحليلات أساسية';

  @override
  String get subscriptionFreeNoTeams => 'بدون ميزات الفرق';

  @override
  String get subscriptionFreeNoAnalytics => 'بدون تحليلات متقدمة';

  @override
  String get subscriptionFreeNoApi => 'بدون وصول إلى API';

  @override
  String get subscriptionEverythingInFree => 'كل ما في الخطة المجانية';

  @override
  String subscriptionTeamLimit(num count) {
    return 'إنشاء فرق تصل إلى $count أعضاء';
  }

  @override
  String subscriptionHistoryLimit(num count) {
    return 'سجل ممتد ($count عنصر)';
  }

  @override
  String get subscriptionPrioritySupport => 'دعم ذو أولوية';

  @override
  String get subscriptionEverythingInBasic => 'كل ما في الخطة الأساسية';

  @override
  String get subscriptionAdvancedAnalytics => 'تحليلات متقدمة';

  @override
  String get subscriptionApiAccess => 'وصول إلى API للتكامل';

  @override
  String get subscriptionEverythingInProfessional =>
      'كل ما في الخطة الاحترافية';

  @override
  String subscriptionUnlimitedMembers(num count) {
    return 'أعضاء فريق غير محدودين (حتى $count)';
  }

  @override
  String get subscriptionCustomBranding => 'هوية بصرية مخصصة';

  @override
  String get subscriptionPremiumSupport => 'دعم مميز';

  @override
  String get subscriptionExtendedApi => 'ميزات API موسعة';

  @override
  String get subscriptionContactUs =>
      'تحتاج المزيد؟ تواصل معنا للحصول على خطة مخصصة.';

  @override
  String get subscriptionFeaturesHeading => 'المزايا';

  @override
  String get subscriptionLimitationsHeading => 'القيود';

  @override
  String get subscriptionPopularBadge => 'الأكثر شيوعًا';

  @override
  String get subscriptionCurrentPlan => 'خطتك الحالية';

  @override
  String get subscriptionDowngrade => 'تخفيض الخطة';

  @override
  String get subscriptionUpgrade => 'ترقية';

  @override
  String get subscriptionSubscribe => 'اشتراك';

  @override
  String subscriptionCurrentPlanLabel(String tierName) {
    return 'الخطة الحالية: $tierName';
  }

  @override
  String subscriptionExpiryLabel(String date) {
    return 'تاريخ الانتهاء: $date';
  }

  @override
  String get subscriptionNoExpiry => 'بدون تاريخ انتهاء';

  @override
  String subscriptionStatusLabel(String status) {
    return 'الحالة: $status';
  }

  @override
  String subscriptionTeamsFeatureLabel(String availability) {
    return 'ميزة الفرق: $availability';
  }

  @override
  String get subscriptionActive => 'نشط';

  @override
  String get subscriptionExpired => 'منتهٍ';

  @override
  String get subscriptionAvailable => 'متاحة';

  @override
  String get subscriptionNotAvailable => 'غير متاحة';

  @override
  String get subscriptionRefreshStatus => 'تحديث الحالة';

  @override
  String get subscriptionStatusUpdated => 'تم تحديث حالة الاشتراك بنجاح';

  @override
  String get subscriptionRefreshFailed =>
      'تعذر تحديث حالة الاشتراك. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String subscriptionUpdateError(String error) {
    return 'خطأ في تحديث الاشتراك: $error';
  }

  @override
  String get subscriptionDowngradeTitle => 'تخفيض الخطة؟';

  @override
  String get subscriptionChangeTitle => 'تغيير الخطة؟';

  @override
  String subscriptionDowngradeMessage(String planName) {
    return 'هل أنت متأكد من أنك تريد التخفيض إلى خطة $planName؟ قد تفقد الوصول إلى بعض الميزات.';
  }

  @override
  String subscriptionChangeMessage(String planName) {
    return 'هل أنت متأكد من أنك تريد التغيير إلى خطة $planName؟';
  }

  @override
  String get subscriptionChange => 'تغيير';

  @override
  String get subscriptionPaymentTitle => 'أكمل اشتراكك';

  @override
  String get subscriptionPaymentMessage =>
      'في تطبيق حقيقي، سيعرض هذا نموذج دفع باستخدام Stripe أو PayPal. في هذه النسخة التجريبية، سنحاكي عملية دفع ناجحة.';

  @override
  String get subscriptionSimulatePayment => 'محاكاة الدفع';

  @override
  String subscriptionErrorLoad(String error) {
    return 'فشل تحميل الاشتراك: $error';
  }

  @override
  String subscriptionErrorUpdate(String error) {
    return 'فشل تحديث الاشتراك: $error';
  }

  @override
  String get subscriptionErrorUpdateFailed => 'فشل تحديث الاشتراك';
}
