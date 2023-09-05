import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webauthn/webauthn.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();

    // Change the default factory. On iOS/Android, if not using `sqlite_flutter_lib` you can forget
    // this step, it will use the sqlite version available on the system.
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

const makeCredentialJson = '''{
    "authenticatorExtensions": "",
    "clientDataHash": "LTCT/hWLtJenIgi0oUhkJz7dE8ng+pej+i6YI1QQu60=",
    "credTypesAndPubKeyAlgs": [
        ["public-key", -7]
    ],
    "excludeCredentials": [{
        "type": "public-key",
        "id": "lVGyXHwz6vdYignKyctbkIkJto/ADbYbHhE7+ss/87o="
    }],
    "requireResidentKey": true,
    "requireUserPresence": true,
    "requireUserVerification": false,
    "rp": {
        "name": "webauthn.io",
        "id": "webauthn.io"
    },
    "user": {
        "name": "testuser",
        "displayName": "Test User",
        "id": "/QIAAAAAAAAAAA=="
    }
}''';

const getAssertionJson = '''{
    "allowCredentialDescriptorList": [{
        "id": "jVtTOKLHRMN17I66w48XWuJadCitXg0xZKaZvHdtW6RDCJhxO6Cfff9qbYnZiMQ1pl8CzPkXcXEHwpQYFknN2w==",
        "type": "public-key"
    }],
    "authenticatorExtensions": "",
    "clientDataHash": "LTCT/hWLtJenIgi0oUhkJz7dE8ng+pej+i6YI1QQu60=",
    "requireUserPresence": true,
    "requireUserVerification": false,
    "rpId": "webauthn.io"
}''';

class CredentialData {
  final String username;
  final Attestation attestation;

  CredentialData(this.username, this.attestation);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebAuthn Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'WebAuthn Flutter Plugin Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _auth = Authenticator(true, false);
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _optionsController = TextEditingController();

  final _credentials = <CredentialData>[];
  int? _highlightCredentialIdx;

  bool _processing = false;

  Future<T?> _lockAndExecute<T>(
      bool validate, Future<T> Function() callback) async {
    T? result;
    if (!_processing) {
      setState(() {
        _processing = true;
      });

      try {
        bool valid = true;
        if (validate) {
          final data = _formKey.currentState;
          if (data == null || !data.validate()) {
            valid = false;
          }
        }

        if (valid) {
          result = await callback();
        }
      } on Exception catch (e) {
        _snackBar(e.toString());
      } finally {
        setState(() {
          _processing = false;
        });
      }
    }
    return result;
  }

  void _startResetSelection() {
    Future.delayed(const Duration(seconds: 2)).then((_) => {
          setState(() {
            _highlightCredentialIdx = null;
          })
        });
  }

  void _snackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  void _showOptionsDialog(
    String title,
    Object options,
    void Function() onCreate,
  ) {
    const encoder = JsonEncoder.withIndent('  ');
    final prettyJson = encoder.convert(options);

    _optionsController.text = prettyJson;

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog.fullscreen(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TextField(
                  controller: _optionsController,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                ),
              ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onCreate();
                  },
                  child: const Text('Create'),
                ),
                const SizedBox(width: 30),
                TextButton(
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data != null && data.text != null) {
                      _optionsController.text = data.text!;
                    }
                  },
                  child: const Text('From Clipboard'),
                ),
                const SizedBox(width: 30),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateCredential() {
    final username = _usernameController.text.trim();
    final options =
        MakeCredentialOptions.fromJson(json.decode(makeCredentialJson));
    options.userEntity = UserEntity(
      id: Uint8List.fromList(username.codeUnits),
      displayName: username,
      name: username,
    );

    _showOptionsDialog('Create Credential Options', options, _createCredential);
  }

  void _createCredential() async {
    final credential = await _lockAndExecute(false, () async {
      try {
        final optionsJson = _optionsController.text.trim();
        final options =
            MakeCredentialOptions.fromJson(json.decode(optionsJson));

        final attestation = await _auth.makeCredential(options);
        final credential = CredentialData(options.userEntity.name, attestation);

        setState(() {
          _usernameController.text = '';
          _highlightCredentialIdx = _credentials.length;
          _credentials.add(credential);
        });
        _startResetSelection();

        return credential; // attestation.getCredentialIdBase64();
      } on AuthenticatorException catch (e) {
        _snackBar('Attestation error: ${e.message}');
        return null;
      }
    });

    if (credential != null) {
      final credentialId = credential.attestation.getCredentialIdBase64();
      _snackBar('Attestation created: $credentialId');
      _showCredentialDetails(credential);
    }
  }

  void _showCredentialDetails(CredentialData credential) {
    const encoder = JsonEncoder.withIndent('  ');
    final rawJson = credential.attestation.asJSON();
    final prettyJson = encoder.convert(json.decode(rawJson));

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog.fullscreen(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Full Attestation Payload',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SelectableText(
                prettyJson,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: rawJson));
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () async {
                      final credentialId =
                          credential.attestation.getCredentialIdBase64();
                      final response = json.encode({
                        'type': 'public-key',
                        'id': credentialId,
                        'rawId': credentialId,
                        'response': {
                          'clientDataJSON': '',
                          'attestationObject': WebAPI.base64Encode(
                              credential.attestation.asCBOR()),
                        },
                      });

                      await Clipboard.setData(ClipboardData(text: response));
                    },
                    child: const Text('Copy Response'),
                  ),
                  const SizedBox(width: 30),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateAssertion() {
    final username = _usernameController.text.trim();
    final options = GetAssertionOptions.fromJson(json.decode(getAssertionJson));
    // Only allow credentials currently in the state with a matching username
    // The requesting server should be doing this and sending which credentials
    // they are expecting you to try to verify.
    options.allowCredentialDescriptorList = _credentials
        .where((e) => e.username == username)
        .map((e) => PublicKeyCredentialDescriptor(
            type: PublicKeyCredentialType.publicKey,
            id: e.attestation.getCredentialId()))
        .toList();

    // User not found
    if (username.isNotEmpty && options.allowCredentialDescriptorList!.isEmpty) {
      _snackBar('Error: Username not found');
      return;
    }

    _showOptionsDialog('Create Assertion Options', options, _createAssertion);
  }

  void _createAssertion() async {
    final assertion = await _lockAndExecute(false, () async {
      try {
        final optionsJson = _optionsController.text.trim();
        final options = GetAssertionOptions.fromJson(json.decode(optionsJson));

        final assertion = await _auth.getAssertion(options);
        final credentialId =
            WebAPI.base64Encode(assertion.selectedCredentialId);
        final credentialIdx = _credentials.indexWhere(
            (e) => e.attestation.getCredentialIdBase64() == credentialId);

        setState(() {
          _usernameController.text = '';
          _highlightCredentialIdx = credentialIdx >= 0 ? credentialIdx : null;
        });
        _startResetSelection();

        return assertion;
      } on AuthenticatorException catch (e) {
        _snackBar('Assertion error: ${e.message}');
        return null;
      }
    });

    if (assertion != null) {
      final credentialId = WebAPI.base64Encode(assertion.selectedCredentialId);
      _snackBar('Assertion succeeded for: $credentialId');
      _showAssertionDetails(assertion);
    }
  }

  void _showAssertionDetails(Assertion assertion) {
    final assertionResponse = {
      'id': WebAPI.base64Encode(assertion.selectedCredentialId),
      'rawId': WebAPI.base64Encode(assertion.selectedCredentialId),
      'type': 'public-key',
      'response': {
        'authenticatorData': WebAPI.base64Encode(assertion.authenticatorData),
        'clientDataJSON': '',
        'signature': WebAPI.base64Encode(assertion.signature),
        'userHandle':
            WebAPI.base64Encode(assertion.selectedCredentialUserHandle),
      },
    };

    const encoder = JsonEncoder.withIndent('  ');
    final rawJson = json.encode(assertionResponse);
    final prettyJson = encoder.convert(assertionResponse);

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog.fullscreen(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Full Assertion Payload',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SelectableText(
                prettyJson,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: rawJson));
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: rawJson));
                    },
                    child: const Text('Copy Response'),
                  ),
                  const SizedBox(width: 30),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: ListView.separated(
                  reverse: true,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    // Header row
                    if (index == _credentials.length) {
                      return const SizedBox(
                        height: 50,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Username',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Credential ID',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final creds = _credentials[index];
                    onCredentialTap() {
                      _showCredentialDetails(creds);
                    }

                    return InkWell(
                      onTap: onCredentialTap,
                      child: Container(
                        color: (_highlightCredentialIdx != null &&
                                _highlightCredentialIdx == index)
                            ? theme.colorScheme.secondary
                            : theme.scaffoldBackgroundColor,
                        height: 50,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: SelectableText(
                                  creds.username,
                                  onTap: onCredentialTap,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: SelectableText(
                                  creds.attestation.getCredentialIdBase64(),
                                  onTap: onCredentialTap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(),
                  itemCount: _credentials.isEmpty ? 0 : _credentials.length + 1,
                ),
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(hintText: 'Username'),
                maxLength: 15,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.length > 15) {
                    return 'Username is too long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _processing ? null : _showCreateCredential,
                    child: const Text('Register'),
                  ),
                  const SizedBox(width: 30),
                  ElevatedButton(
                    onPressed: _processing ? null : _showCreateAssertion,
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
