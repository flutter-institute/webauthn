import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/types/auth_messages_ios.dart';
import 'package:local_auth_windows/types/auth_messages_windows.dart';

/// Options to pass custom localized strings to the LocalAuth plugin
/// See [LocalAuthentication.authenticate] for the messages
class AuthenticationLocalizationOptions {
  /// The message to show the user while prompting them for authentication.
  /// This is typically along the lines of 'Authenticate to acce MyApp.'.
  final String? localizedReason;

  /// Platform specific messages that can be used to customize messages in the dialogs.
  final Iterable<AuthMessages> authMessages;

  /// Whether the system will attempt to handle user-fixable issues encountered
  /// while authenticating.
  final bool userErrorDialogs;

  const AuthenticationLocalizationOptions({
    this.localizedReason,
    this.userErrorDialogs = true,
    this.authMessages = const <AuthMessages>[
      IOSAuthMessages(),
      AndroidAuthMessages(),
      WindowsAuthMessages(),
    ],
  });
}
