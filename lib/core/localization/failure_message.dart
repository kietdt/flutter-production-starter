// Core Localization Module
// Responsibility: Turn a domain `Failure` into user-facing text.
//
// Failures carry no strings (see core/error/failures.dart); widgets call
// `failure.message(context.l10n)` so the text follows the active language.
// Screens that need a more specific message for a failure (e.g. login's 401 →
// "wrong credentials") switch on the failure type themselves first.

import 'package:flutter_production_starter/core/config/app_config.dart';
import 'package:flutter_production_starter/core/error/failures.dart';
import 'package:flutter_production_starter/core/localization/app_language.dart';

extension FailureMessage on Failure {
  String message(AppLanguage l10n) {
    final Failure failure = this;
    switch (failure) {
      case NetworkFailure(:final reason):
        return reason.message(l10n);
      case UnauthorizedFailure():
        return l10n.errorUnauthorized;
      case ServerFailure(:final serverMessage):
        final bool showServerMessage =
            AppConfig.instance.useServerErrorMessage &&
                serverMessage != null &&
                serverMessage.isNotEmpty;
        return showServerMessage ? serverMessage : l10n.errorServer;
      case CancelledFailure():
        return l10n.errorCancelled;
      case UnknownFailure():
        return l10n.errorUnknown;
    }
  }
}

extension NetworkFailureReasonMessage on NetworkFailureReason {
  String message(AppLanguage l10n) {
    switch (this) {
      case NetworkFailureReason.timeout:
        return l10n.errorTimeout;
      case NetworkFailureReason.noConnection:
        return l10n.errorNoConnection;
    }
  }
}
