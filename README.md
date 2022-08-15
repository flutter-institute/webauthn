# webauthn

This plugin is meant to implement the [WebAuthn Authenticator Model](https://www.w3.org/TR/webauthn/#sctn-authenticator-model). This model is heavily based off the [DuoLabs Android Implementation](https://github.com/duo-labs/android-webauthn-authenticator) of this library.

This plugin relies on the [local_auth plugin](https://pub.dev/packages/local_auth), so it can only support the platforms supported by that plugin.

## Getting Started

### Updated Android to use FlutterFragmentActivity

To use local_auth in Android you will need to update your main activity to be a FlutterFragmentActivity. See the example app.

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
