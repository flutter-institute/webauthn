## 0.2.2

* Fixing the DER serialization of signature data to ensure values are treated as positive integers
* Fixing sha256 hash to use UTF8 instead of UTF16
* Updating crypto_keys to latest version

## 0.2.1

* Updating dependencies to latest version except collections which is pinned by the sdk
* Fixing a dart format issue

## 0.2.0

* Updating byte_extensions to 0.0.3 to fix broken keys
* Base64 URL encoded strings no longer contain trailing '='
* Adding helper methods base64Encode/Decode to WebAPI
* Updating example app to use WebAPI.base64 helpers

## 0.1.0

* Adding support for packed attestations when a new credential is created
* Adding support for basic conversions between the authenticator and web API options
* Switching to return a packed attestation by default
* Adding toJson() handling to attestation objects
* Updating dependencies to latest versions

## 0.0.5+1

* Updating example app to add windows and linux sqflite support

## 0.0.5

* Updating byte handling to use the byte_extensions package
* Updating dependencies to latest versions

## 0.0.4

* Unpinning mockito version
* Adding codemagic build status
* Updating dependencies to latest versions

## 0.0.3

* Updating username validation to use the precis package

## 0.0.2

* Restricting access to the private parts of the Authenticator
* Adding dartdoc comments to all members of the public API

## 0.0.1+1

* Actually adding the changelog text
* Updating unit tests to use properly ensureInitialized method for test widgets

## 0.0.1

* Initial release allowing for creating Attestations and Assertions
* This release is not fully standard compliant as it is lacking full UTF-8 support and credential selection
