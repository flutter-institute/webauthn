# webauthn

This plugin is meant to implement the [WebAuthn Authenticator Model](https://www.w3.org/TR/webauthn/#sctn-authenticator-model). This model is heavily based off the [DuoLabs Android Implementation](https://github.com/duo-labs/android-webauthn-authenticator) of this library.

This plugin relies on the [local_auth plugin](https://pub.dev/packages/local_auth), so it can only support the platforms supported by that plugin.

## Getting Started

### Setting up local_auth

We rely on local_auth in the background, so you need to configure your apps to work properly
with this plugin. See the [iOS Integration](https://pub.dev/packages/local_auth#ios-integration) and [Android Integration](https://pub.dev/packages/local_auth#android-integration) sections.

If you want customize the dialog messages for the biometric prompt, you will need to add the platform-specific local_auth implementation packages (See the "Dialogs" section of the [Usage](https://pub.dev/packages/local_auth#usage) instructions on local_auth). These custom messages can then be passed to `Authenticator.makeCredential`.

### Configure Android Version

Because we need to use flutter_secure_storage we have a minimum SDK requirement.
In `[project]/android/app/build.gradle` set `minSdkVersion` to >= 18.

```
android {
    ...
    defaultConfig {
        ...
        minSdkVersion 18
        ...
    }
}
```

This project uses [code generated libraries](https://docs.flutter.dev/development/data-and-backend/json#serializing-json-using-code-generation-libraries) for JSON handling with classes.

To generate code once, use `flutter pub run build_runner build`. To continuously regenerate use `flutter pub run build_runner watch`.

## Testing

## Usage
