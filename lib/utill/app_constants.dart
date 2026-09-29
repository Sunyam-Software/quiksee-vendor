import 'package:quiksee/features/language/domain/models/language_model.dart';
import 'images.dart';

class AppConstants {
  static const String companyName = 'Quiksee';
  static const String appName = 'Deliveryman';
  static const bool demo = false;
  static const int imageQuality = 100;
  static const String appVersion = '4.1.2';
  static const String polylineMapKey = 'AIzaSyDAzcDcfpGhFzA3CUx3b_9HOIl8oGTGeMI';

  static const String baseUrl = 'https://quiksee.in';

  static const String profileUri = '/api/v2/delivery-man/info';
  static const String configUri = '/api/v1/config';
  static const String deliveryManAuthPrefix = '/api/v2/delivery-man/auth';
  static const String loginUri = '$deliveryManAuthPrefix/login';
  static const String dmRegistrationConfigUri =
      '$deliveryManAuthPrefix/registration-config';
  static const String dmRegistrationUri = '$deliveryManAuthPrefix/registration';
  static const String dmRegistrationSendOtpUri =
      '$deliveryManAuthPrefix/registration-send-otp';
  static const String dmRegistrationVerifyOtpUri =
      '$deliveryManAuthPrefix/registration-verify-otp';
  static const String dmPasswordRecoveryConfigUri =
      '$deliveryManAuthPrefix/password-recovery-config';
  static const String forgotPassword = '$deliveryManAuthPrefix/forgot-password';
  static const String verifyOtp = '$deliveryManAuthPrefix/verify-otp';
  static const String resetPassword = '$deliveryManAuthPrefix/reset-password';
  static const String currentOrderUri = '/api/v2/delivery-man/current-orders';
  static const String orderDetailsUri = '/api/v2/delivery-man/order-details?order_id=';
  static const String allOrderHistoryUri = '/api/v2/delivery-man/all-orders';
  static const String recordLocationUri = '/api/v2/delivery-man/record-location-data';
  static const String updateOrderStatusUri = '/api/v2/delivery-man/update-order-status';
  static const String rejectAssignedOrderUri = '/api/v2/delivery-man/reject-assigned-order';
  static const String rescheduleOrderStatusUri = '/api/v2/delivery-man/update-expected-delivery';
  static const String pauseAndResumeOrderStatusUri = '/api/v2/delivery-man/order-update-is-pause';
  static const String updatePaymentStatusUri = '/api/v2/delivery-man/update-payment-status';
  static const String createCodUpiQrUri = '/api/v2/delivery-man/cod-upi-qr/create';
  static const String codUpiQrStatusUri = '/api/v2/delivery-man/cod-upi-qr/status';
  static const String markCodCashCollectedUri = '/api/v2/delivery-man/cod-cash-collected';
  static const String tokenUri = '/api/v2/delivery-man/update-fcm-token';
  static const String searchConversationListUri = '/api/v2/delivery-man/update-fcm-token';
  static const String statusOnOffUri = '/api/v2/delivery-man/is-online';
  static const String withdrawRequestUri = '/api/v2/delivery-man/withdraw-request';
  static const String walletInfoUri = '/api/v2/delivery-man/wallet';
  static const String orderCountUri = '/api/v2/delivery-man/order-count';
  static const String deliveryWiseEarnedUri = '/api/v2/delivery-man/delivery-wise-earned';
  static const String tipSummaryUri = '/api/v2/delivery-man/tip/summary';
  static const String tipListUri = '/api/v2/delivery-man/tip/list';
  static const String tipOrderUri = '/api/v2/delivery-man/tip/order';
  static const String orderListFilterByDate = '/api/v2/delivery-man/order-list-by-date';
  static const String orderSearchUri = '/api/v2/delivery-man/search';
  static const String profileUpdateUri = '/api/v2/delivery-man/update-info';
  static const String chatListUri = '/api/v2/delivery-man/messages/list/';
  static const String messageListUri = '/api/v2/delivery-man/messages/get-message/';
  static const String sendMessageUri = '/api/v2/delivery-man/messages/send-message/';
  static const String withdrawListUri = '/api/v2/delivery-man/withdraw-list-by-approved';
  static const String emergencyContactList = '/api/v2/delivery-man/emergency-contact-list';
  static const String depositedList = '/api/v2/delivery-man/collected_cash_history';
  static const String reviewListUri = '/api/v2/delivery-man/review-list';
  static const String updateBankInfo = '/api/v2/delivery-man/bank-info';
  static const String distanceApi = '/api/v2/delivery-man/distance-api';
  static const String distanceShippingConfigUri = '/api/v2/delivery-man/distance-shipping-config';
  static const String orderDistancePaymentUri = '/api/v2/delivery-man/order-distance-payment';
  static const String estimateDeliveryPayUri = '/api/v2/delivery-man/estimate-delivery-pay';
  static const String pendingOffersUri = '/api/v2/delivery-man/pending-offers';
  static const String scheduledPendingOffersUri =
      '/api/v2/delivery-man/scheduled-delivery/pending-offers';
  static const String scheduledCurrentOrdersUri =
      '/api/v2/delivery-man/scheduled-delivery/current-orders';
  static const String scheduledAllOrdersUri =
      '/api/v2/delivery-man/scheduled-delivery/all-orders';
  static const String scheduledDeliveryConfigUri =
      '/api/v2/delivery-man/scheduled-delivery/config';
  static const String acceptOfferUri = '/api/v2/delivery-man/accept-offer';
  static const String rejectOfferUri = '/api/v2/delivery-man/reject-offer';
  static const String assignmentSettingsUri = '/api/v2/delivery-man/assignment-settings';
  static const String deliveryAreasUri = '/api/v2/delivery-man/delivery-areas';
  static const String updateLiveLocationUri = '/api/v2/delivery-man/update-live-location';
  static const String chatSearch = '/api/v2/delivery-man/messages/search/';
  static const String addToSavedReviewList = '/api/v2/delivery-man/save-review';
  static const String deliveryVerificationImage = '/api/v2/delivery-man/order-delivery-verification';
  static const String otpVerificationForOrder = '/api/v2/delivery-man/verify-order-delivery-otp';
  static const String resendVerificationCode = '/api/v2/delivery-man/resend-verification-code';
  static const String pickupOtpUri = '/api/v2/delivery-man/pickup-otp';
  static const String storeWaitUri = '/api/v2/delivery-man/store-wait';
  static const String storeWaitPokeUri = '/api/v2/delivery-man/store-wait/poke';
  static const String orderTransferCandidatesUri =
      '/api/v2/delivery-man/order/transfer/candidates';
  static const String orderTransferRequestUri =
      '/api/v2/delivery-man/order/transfer/request';
  static const String orderTransferStatusUri =
      '/api/v2/delivery-man/order/transfer/status';
  static const String orderTransferCancelUri =
      '/api/v2/delivery-man/order/transfer/cancel';
  static const String orderTransferRespondUri =
      '/api/v2/delivery-man/order/transfer/respond';
  static const String orderTransferPendingIncomingUri =
      '/api/v2/delivery-man/order/transfer/pending-incoming';
  static const String orderTransferRecentOutgoingUri =
      '/api/v2/delivery-man/order/transfer/recent-outgoing';
  static const String setCurrentLanguageUri = '/api/v2/delivery-man/language-change';
  static const String singleOrderHistoryUri = '/api/v2/delivery-man/order-item';
  static const String businessPagesUri = '/api/v1/business-pages?type=';


  // Shared Key
  static const String theme = 'theme';
  static const String token = 'token';
  static const String countryCode = 'country_code';
  static const String languageCode = 'language_code';
  static const String cartList = 'cart_list';
  static const String userPassword = 'user_password';
  static const String userEmail = 'user_email';
  static const String currency = 'currency';
  static const String cachedConfigJson = 'cached_config_json';
  static const String topic = 'quiksee_delivery';
  static const String maintenanceModeTopic = 'maintenance_mode_start_deliveryman';
  static const String intro = 'quiksee_delivery';
  static const String driverAcceptedOrders = 'driver_accepted_orders';
  static const String pendingWakeOrderId = 'pending_wake_order_id';
  static const String pendingWakeOrderType = 'pending_wake_order_type';
  static const String pendingWakeOfferId = 'pending_wake_offer_id';
  static const String pendingWakeStoredAtMs = 'pending_wake_stored_at_ms';
  static const String pendingVendorReadyOrderId = 'pending_vendor_ready_order_id';
  static const String pendingVendorReadyDescription =
      'pending_vendor_ready_description';
  static const String pendingVendorReadyStoredAtMs =
      'pending_vendor_ready_stored_at_ms';
  static const String dismissedVendorReadyOrderIds =
      'dismissed_vendor_ready_order_ids';
  static const String invalidAssignmentOfferIds = 'invalid_assignment_offer_ids';
  static const String reachedRestaurantOrderIds = 'reached_restaurant_order_ids';
  static const String newOrderAlertActiveAt = 'new_order_alert_active_at';
  static const String newOrderAlertMutedUntil = 'new_order_alert_muted_until';
  static const String newOrderAlertMutedOfferId = 'new_order_alert_muted_offer_id';
  static const String nativeAlertStopRequested = 'native_alert_stop_requested';
  static const String pendingOfferCancelOfferId = 'pending_offer_cancel_offer_id';
  static const String pendingOfferCancelOrderId = 'pending_offer_cancel_order_id';
  static const String pendingOfferCancelReason = 'pending_offer_cancel_reason';
  static const String pendingOfferCancelDescription =
      'pending_offer_cancel_description';
  static const String pendingOfferCancelType = 'pending_offer_cancel_type';
  static const String pendingNavigationDeliverOrderId =
      'pending_navigation_deliver_order_id';
  static const String pendingNavigationReturnOrderId =
      'pending_navigation_return_order_id';
  static const String activeExternalNavOrderId = 'active_external_nav_order_id';
  static const String activeExternalNavDestLat = 'active_external_nav_dest_lat';
  static const String activeExternalNavDestLng = 'active_external_nav_dest_lng';
  static const String activeExternalNavDestLabel = 'active_external_nav_dest_label';
  static const String permissionsSetupCompleted = 'permissions_setup_completed';
  static const String permissionReminderDismissedAt =
      'permission_reminder_dismissed_at';
  static const String oemBackgroundSetupDone = 'oem_background_setup_done';
  static const String driverOnlineNative = 'driver_online';
  static const String forceStopWarningShownAt = 'force_stop_warning_shown_at';
  static const String localizationKey = 'X-localization';
  static const String notificationCount = 'count';
  static const String notificationSound = 'sound';
  static const String userCountryCode = 'user_country_code';

  /// COD UPI collect (from merchant QR: QUIKSEE PRIVATE LIMITED).
  static const String codUpiVpa = '7696004866.1@hdfc';
  static const String codUpiPayeeName = 'QUIKSEE PRIVATE LIMITED';


  static List<LanguageModel> languages = [
    LanguageModel(imageUrl: Images.unitedKindom, languageName: 'English', countryCode: 'US', languageCode: 'en'),
  ];

  static const int limitOfPickedIdentityImageNumber = 2;
  static const double limitOfPickedImageSizeInMB = 2;
  static const double balanceInputLength = 10;

  static const double maxLimitOfFileSentINConversation = 25;
  static const double maxLimitOfTotalFileSent = 5;
  static const double maxSizeOfASingleFile = 2;
  static const int fileImageMaxLimit = 2;


  static const List<String> videoExtensions = [
    'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mpeg', 'mpg', 'm4v', '3gp', 'ogv'
  ];

  static const List<String> imageExtensions = ['png', 'jpg', 'jpeg', 'gif', 'webp'];

  static const List<String> documentExtensions = [
    'doc', 'docx', 'txt', 'csv', 'xls', 'xlsx', 'pdf',
  ];


}
