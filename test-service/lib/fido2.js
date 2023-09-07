const { Fido2Lib } = require('fido2-lib');

module.exports = function(options = {}) {
  return new Fido2Lib({
    timeout: 600000,
    rpId: 'example.com',
    rpName: 'ACME',
    rpIcon: 'https://example.com/logo.png',
    challengeSize: 128,
    attestation: 'none',
    cryptoParams: [-7, -257],
    authenticatorAttachment: 'platform',
    authenticatorRequireResidentKey: false,
    authenticatorUserVerification: 'discouraged', // set to "required" or "preferred" to make happen
    ...options,
  });
}
