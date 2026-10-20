// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Restock';

  @override
  String get appTagline => 'Automatic orders with AI + PayPal';

  @override
  String get configErrorTitle => 'Incomplete configuration';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionBack => 'Back';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSend => 'Send';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionCreateAccount => 'Create an account';

  @override
  String get actionSignIn => 'Sign in';

  @override
  String get actionCreateMyStore => 'Create my store';

  @override
  String get actionAlreadyHaveAccount => 'I already have an account';

  @override
  String get actionForgotPassword => 'Forgot your password?';

  @override
  String get actionApproveAndPay => 'Approve and pay with PayPal';

  @override
  String get actionReject => 'Reject';

  @override
  String get actionConfirmDelivery => 'Confirm delivery';

  @override
  String get actionReviewStockNow => 'Review stock now';

  @override
  String get actionRemoveOneUnit => 'Remove one unit';

  @override
  String get actionAddOneUnit => 'Add one unit';

  @override
  String semanticsBackTo(String label) {
    return 'Back to $label';
  }

  @override
  String get semanticsShowPassword => 'Show password';

  @override
  String get semanticsHidePassword => 'Hide password';

  @override
  String get semanticsLess => 'Less';

  @override
  String get semanticsMore => 'More';

  @override
  String get tabHome => 'Home';

  @override
  String get tabStock => 'Stock';

  @override
  String get tabOrders => 'Orders';

  @override
  String get tabRules => 'Rules';

  @override
  String get tabAssistant => 'Assistant';

  @override
  String get homeTitle => 'Today';

  @override
  String get homeToApprove => 'To approve';

  @override
  String get homeRunningOutSoon => 'Running out soon';

  @override
  String get homeAllInOrder => 'All good';

  @override
  String get homeAllInOrderDetail => 'No product is below its minimum';

  @override
  String get homeAgentWorking => 'Working…';

  @override
  String get homeAgentActive => 'Agent active';

  @override
  String homeBudgetOfMonth(String month) {
    return '$month budget';
  }

  @override
  String homeRemaining(String amount) {
    return '$amount left';
  }

  @override
  String get homeAgentTitle => 'Restocking agent';

  @override
  String get homeAgentDescription =>
      'Reviews your stock, prepares orders and pays them with PayPal within your rules.';

  @override
  String get homeReviewing => 'Reviewing…';

  @override
  String get homeNeedsApproval => 'Needs your approval';

  @override
  String get homeAgentFailed => 'Something went wrong';

  @override
  String get homeStockReview => 'Stock review';

  @override
  String get stockSearchPlaceholder => 'Search by name or UID';

  @override
  String get stockFilterAll => 'All';

  @override
  String get stockFilterLow => 'Low stock';

  @override
  String get stockFilterTransit => 'On the way';

  @override
  String get stockEmptyTitle => 'No products yet';

  @override
  String get stockEmptyFilterTitle => 'Nothing matches this filter';

  @override
  String get stockEmptyMessage =>
      'Your suppliers\' catalogues will show up here.';

  @override
  String stockProductCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
      zero: 'No products',
    );
    return '$_temp0';
  }

  @override
  String get stockStatusTransit => 'On the way';

  @override
  String get stockStatusOut => 'Out of stock';

  @override
  String get stockStatusLow => 'Low stock';

  @override
  String get stockStatusOk => 'OK';

  @override
  String stockUnitsMin(int stock, String unit, int min) {
    return '$stock $unit · min. $min';
  }

  @override
  String get stockUpdated => 'Stock updated';

  @override
  String stockUpdatedMessage(String name, int stock, String unit) {
    return '$name: $stock $unit.';
  }

  @override
  String stockEditorUid(String uid, int min, String unit) {
    return '$uid · min. $min $unit';
  }

  @override
  String get ordersTitle => 'Orders';

  @override
  String ordersSpentInMonth(String month) {
    return 'Spent in $month';
  }

  @override
  String get ordersCreatedByAgent => 'Created by the agent';

  @override
  String ordersCreatedByAgentValue(int count, int total) {
    return '$count of $total';
  }

  @override
  String get ordersHistory => 'History';

  @override
  String get ordersEmptyTitle => 'No orders yet';

  @override
  String get ordersEmptyMessage =>
      'Tap “Review stock now” on Home so the agent prepares the first one.';

  @override
  String get ordersDeliveryQuestion => 'Has the order arrived?';

  @override
  String ordersCheckDelivery(String supplier) {
    return 'Check the delivery from $supplier';
  }

  @override
  String get ordersCreatedByAgentWord => 'agent';

  @override
  String get ordersCreatedByYouWord => 'you';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPendingApproval => 'To approve';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusPaying => 'Paying…';

  @override
  String get statusPaid => 'Paid with PayPal';

  @override
  String get statusInvoiced => 'Invoiced';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusPaymentFailed => 'Payment failed';

  @override
  String reasonOverMaxPerOrder(String amount) {
    return 'Over the $amount per-order limit';
  }

  @override
  String reasonOverMonthlyLimit(String amount) {
    return 'Over your $amount monthly limit';
  }

  @override
  String get reasonAnyOrderApproval => 'You ask me about every order';

  @override
  String reasonOverApprovalThreshold(String amount) {
    return 'Over $amount without approval';
  }

  @override
  String get orderUnavailable => 'This order is no longer available';

  @override
  String orderTitle(String supplier) {
    return 'Order to $supplier';
  }

  @override
  String get orderCreatedByAgent => 'Prepared by the agent';

  @override
  String get orderCreatedByYou => 'Created by you';

  @override
  String orderUnitPrice(String price, String uid) {
    return '$price / unit · $uid';
  }

  @override
  String get orderTotal => 'Total';

  @override
  String get orderWhatAgentDecided => 'What the agent decided';

  @override
  String orderConfidence(int percent) {
    return '$percent% confidence';
  }

  @override
  String get orderPaypalPayment => 'PayPal payment';

  @override
  String get orderPaymentDate => 'Payment date';

  @override
  String get orderPaymentStatusSent => 'sent';

  @override
  String get orderBlockedByRules => 'Blocked by your rules';

  @override
  String get orderBlockedHint =>
      'Change your rules in the Rules tab if you want to allow it.';

  @override
  String orderApproveHint(String supplier) {
    return 'On approval, the server pays $supplier and issues the invoice.';
  }

  @override
  String orderSpendAfterPayment(String month) {
    return '$month spending after payment';
  }

  @override
  String orderSpendOf(String spent, String limit) {
    return '$spent of $limit';
  }

  @override
  String get orderLegendSpent => 'Already spent';

  @override
  String get orderLegendThisOrder => 'This order';

  @override
  String get orderPaymentSent => 'Payment sent';

  @override
  String orderPaymentSentMessage(String amount, String supplier) {
    return '$amount sent to $supplier with PayPal.';
  }

  @override
  String get orderPaymentFailed => 'Could not pay';

  @override
  String get orderRejectQuestion => 'Reject the order?';

  @override
  String orderRejectMessage(String supplier) {
    return 'The agent will not pay $supplier.';
  }

  @override
  String get orderRejected => 'Order rejected';

  @override
  String get orderRejectFailed => 'Could not reject';

  @override
  String deliveryTitle(String supplier) {
    return 'Delivery from $supplier';
  }

  @override
  String get deliverySubtitle =>
      'Adjust what arrived. Anything missing can be claimed.';

  @override
  String get deliveryComingSoon => 'Coming soon';

  @override
  String get deliveryComingSoonMessage =>
      'AI reading of the delivery note is coming soon.';

  @override
  String get deliveryPhoto => 'Delivery note photo';

  @override
  String deliveryOrderedMissing(int qty, int missing) {
    return 'Ordered $qty · $missing missing';
  }

  @override
  String deliveryOrderedComplete(int qty) {
    return 'Ordered $qty · complete';
  }

  @override
  String get deliveryRegistered => 'Delivery recorded';

  @override
  String get deliveryRegisteredMessage =>
      'What arrived from the order has been saved.';

  @override
  String deliveryClaim(int units, String amount) {
    return 'Claim $units units · $amount';
  }

  @override
  String get deliveryClaimReady => 'Claim prepared';

  @override
  String get deliveryClaimMessage => 'Tell them about the missing units.';

  @override
  String get assistantTitle => 'Assistant';

  @override
  String get assistantSubtitle => 'Your restocking agent';

  @override
  String get assistantGreeting =>
      'Hi. I review your stock, prepare orders for your suppliers and pay them with PayPal, always within your spending rules.';

  @override
  String get assistantChipReview => 'Review the stock now';

  @override
  String get assistantChipPending => 'What do I need to approve?';

  @override
  String get assistantChipSpent => 'How much have I spent?';

  @override
  String get assistantInputHint => 'Ask anything';

  @override
  String get assistantTyping => 'Reviewing your stock…';

  @override
  String get assistantSend => 'Send';

  @override
  String get assistantPendingEmpty =>
      'You have no orders waiting for approval.';

  @override
  String assistantPendingList(int count, String list) {
    return 'You have $count to approve: $list. You will find them on Home.';
  }

  @override
  String get assistantPendingQuestion => 'What do I need to approve?';

  @override
  String get assistantSpentQuestion => 'How much have I spent?';

  @override
  String assistantSpentAnswer(
    String spent,
    String month,
    String limit,
    String remaining,
  ) {
    return 'You have spent **$spent** in $month out of a limit of **$limit**. **$remaining** left.';
  }

  @override
  String get rulesTitle => 'Rules';

  @override
  String get rulesSubtitle => 'The agent only pays if all of them are met';

  @override
  String get rulesSpending => 'Spending';

  @override
  String get rulesAccount => 'Account';

  @override
  String get rulesMonthlyLimit => 'Monthly limit';

  @override
  String rulesMonthlyLimitText(String amount) {
    return 'Don\'t spend more than $amount per month';
  }

  @override
  String rulesMonthlySpent(String amount) {
    return 'You have spent $amount';
  }

  @override
  String get rulesMaxPerOrder => 'Maximum per order';

  @override
  String rulesMaxPerOrderText(String amount) {
    return 'No order can exceed $amount';
  }

  @override
  String get rulesApproval => 'Asks for approval';

  @override
  String get rulesApprovalTextAny => 'Ask me about any order';

  @override
  String rulesApprovalTextAbove(String amount) {
    return 'If an order goes over $amount, ask me';
  }

  @override
  String get rulesSuppliers => 'Suppliers';

  @override
  String get rulesSuppliersTextAny => 'You can buy from any supplier';

  @override
  String rulesSuppliersTextList(String list) {
    return 'Buy only from $list';
  }

  @override
  String get rulesHint =>
      'Tap a rule to change it. Rules are enforced by the system, not by the AI.';

  @override
  String get rulesSession => 'Session';

  @override
  String get rulesAppearance => 'Appearance';

  @override
  String get rulesThemeAuto => 'Auto';

  @override
  String get rulesThemeLight => 'Light';

  @override
  String get rulesThemeDark => 'Dark';

  @override
  String get rulesLanguage => 'Language';

  @override
  String get rulesLanguageAuto => 'Auto';

  @override
  String get rulesLanguageSpanish => 'Spanish';

  @override
  String get rulesLanguageEnglish => 'English';

  @override
  String get rulesSignOutQuestion => 'Sign out?';

  @override
  String get rulesSignOutCancel => 'Cancel';

  @override
  String get rulesSignOutConfirm => 'Sign out';

  @override
  String get rulesSaved => 'Rules saved';

  @override
  String get rulesSavedMessage =>
      'Your spending limits and suppliers are now in place.';

  @override
  String get rulesSaveFailed => 'Could not save the rules';

  @override
  String get rulesMonthlyLimitSheetHint =>
      'It cannot be lower than the maximum per order.';

  @override
  String get rulesMaxPerOrderSheetHint => 'It must be greater than 0.';

  @override
  String get rulesApprovalSheetTitle => 'Ask for approval from';

  @override
  String get rulesApprovalSheetHint => 'With 0 you ask me about any order.';

  @override
  String get rulesSuppliersSheetTitle => 'Allowed suppliers';

  @override
  String get rulesSuppliersSheetHint =>
      'If you don\'t select any, the agent can buy from everyone.';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'At least 6 characters';

  @override
  String get authConfirmPassword => 'Repeat the password';

  @override
  String get authStoreName => 'Your store name';

  @override
  String get authStoreNameHint => 'Lumbre Store';

  @override
  String get authEmailHint => 'you@yourshop.com';

  @override
  String get authSignInFailed => 'Could not sign in';

  @override
  String get authMissingFields => 'Missing data';

  @override
  String get authMissingFieldsBody => 'Fill in the email and the password.';

  @override
  String get authMissingEmail => 'Missing email';

  @override
  String get authMissingEmailBody => 'Write your email first.';

  @override
  String get authEmailSent => 'Email sent';

  @override
  String get authEmailSentBody =>
      'If the email exists, we sent you a recovery link.';

  @override
  String get authFirstTime => 'First time in Restock?';

  @override
  String get authFirstTimeBody =>
      'Create your store and let the agent restock it.';

  @override
  String get authCreateTitle => 'Create account';

  @override
  String get authCreateSubtitle =>
      'Create your store and start restocking in seconds';

  @override
  String get authCreateFailed => 'Could not create the account';

  @override
  String get authCreateMissingFieldsBody =>
      'Fill in the email and both passwords.';

  @override
  String get authPasswordTooShort =>
      'The password must have at least 6 characters.';

  @override
  String get authPasswordTooShortTitle => 'Password too short';

  @override
  String get authPasswordsMismatch => 'The passwords do not match.';

  @override
  String get authPasswordsMismatchTitle => 'Do not match';

  @override
  String get authCreateFooter =>
      'Creating the store is free. You only pay for the orders the agent prepares and you approve, within your rules.';

  @override
  String get errorLoadData => 'We could not load your data';

  @override
  String get errorStoreNotFound => 'The store was not found.';

  @override
  String get errorAgentBusy => 'The agent is already working.';

  @override
  String get errorNoStoreLoaded => 'No store loaded.';

  @override
  String get decisionOrderCreated =>
      'I prepared a restocking order with your low stock.';

  @override
  String get decisionNoAction =>
      'I reviewed the stock: nothing needed ordering.';

  @override
  String get decisionBlocked =>
      'I wanted to order, but your spending rules blocked it.';

  @override
  String get decisionFailed => 'The review failed. Try again in a moment.';

  @override
  String get decisionAutoApproved =>
      'I placed an order within your rules and paid it with PayPal.';

  @override
  String get decisionRequiresApproval =>
      'I prepared an order that needs your approval.';

  @override
  String decisionGeneric(String decision) {
    return 'Agent review: $decision';
  }

  @override
  String get agentChatFallback =>
      'Right now I can review your stock, propose orders and pay them with PayPal within your rules. Tap “Review the stock now” and I\'ll get to it.';

  @override
  String get agentChatTrigger => 'Review the stock now';

  @override
  String dateToday(String time) {
    return 'Today $time';
  }

  @override
  String dateYesterday(String time) {
    return 'Yesterday $time';
  }

  @override
  String get dashboardSignedIn => 'Signed in';

  @override
  String get dashboardUser => 'User';

  @override
  String dashboardStore(String store) {
    return 'Store: $store';
  }

  @override
  String get dashboardNextStep => 'Next step: catalogue, orders and agent.';
}
