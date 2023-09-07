const crypto = require('crypto');

const { WebException } = require('./exceptions');
const { base64Buffer, bufferBase64 } = require('./helpers');
const createFido2 = require('./fido2');

const defaultUserInfo = {
  displayName: 'Test User',
  name: 'testuser',
};

class WebauthnHandler {
  constructor(options = {}) {
    this.f2l = createFido2(options);

    this.credentials = {};
    this.attestations = {};
    this.assertions = {};
  }

  getAllowedCredentials(userId) {
    return Object.keys(this.credentials[userId] ?? {})
      .map(credId => ({
        type: 'public-key',
        id: credId,
      }));
  }

  async createAttestationOptions(userInfo = defaultUserInfo) {
    const rawUserId = crypto.randomBytes(32);
    const userId = rawUserId.toString('base64url');

    const attestationOptions = await this.f2l.attestationOptions();

    const challenge = bufferBase64(attestationOptions.challenge);
    const options = {
      ...attestationOptions,
      challenge,
      user: {
        ...defaultUserInfo,
        ...userInfo,
        id: userId,
      },
    };

    this.attestations[userId] = options;
    return options;
  }

  async verifyAttestationResponse(userId, response) {
    // Get the options for verification
    const options = this.attestations[userId];
    
    // Decode rawId
    const data = {
      ...response,
      rawId: base64Buffer(response.rawId),
    };

    const expected = {
      challenge: options.challenge,
      origin: 'https://example.com',
      factor: 'either',
    };

    const result = await this.f2l.attestationResult(data, expected);
    const credential = result.authnrData;

    this.credentials[userId] = {
      ...(this.credentials[userId] ?? {}),
      [response.id]: credential,
    };

    return credential;
  }

  async createAssertionOptions(userId) {
    const assertionOptions = await this.f2l.assertionOptions();

    const challenge = bufferBase64(assertionOptions.challenge);
    const options = {
      ...assertionOptions,
      challenge,
      allowCredentials: this.getAllowedCredentials(userId),
    };

    this.assertions[userId] = options;
    return options;
  }

  async verifyAssertionResponse(userId, response) {
    // Get the options for verification
    const options = this.assertions[userId];

    const data = {
      ...response,
      rawId: base64Buffer(response.rawId),
    };

    const credential = this.credentials[userId][response.id];
    if (!credential) {
      const message = `Credential '${response.id}' not found for ${userId}`;
      console.error(message, this.credentials[userId]);
      throw new WebException(401, message);
    }

    const expected = {
      challenge: options.challenge,
      origin: 'https://example.com',
      factor: 'either',
      publicKey: credential.get('credentialPublicKeyPem'),
      prevCounter: credential.get('counter'),
      userHandle: base64Buffer(userId),
      allowCredentials: this.getAllowedCredentials(userId),
    };

    const result = await this.f2l.assertionResult(data, expected);
    credential.set('counter', result.authnrData.get('counter'));

    return result.authnrData;
  }
}

module.exports = WebauthnHandler;
