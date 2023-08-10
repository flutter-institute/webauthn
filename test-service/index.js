const crypto = require('crypto');
const { Fido2Lib } = require('fido2-lib');
const readline = require('readline');

const f2l = new Fido2Lib({
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
});

async function prompt(query) {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
    });

    rl.write(query);

    return new Promise(resolve => {
        const lines = [];

        const finish = () => {
            rl.close();
            resolve(lines.join(''));
        };

        let emptyLineCount = 0;
        rl.on('line', line => {
            line = line.trim();
            if (line === '') {
                emptyLineCount += 1;
                if (emptyLineCount == 2) {
                    finish();
                }
            } else {
                lines.push(line);
            }
        })
    });
}

async function doTestCreate() {
    const rawUserId = crypto.randomBytes(32);
    const userId = rawUserId.toString('base64url');

    const registrationOptions = await f2l.attestationOptions();
    

    const challenge = Buffer.from(registrationOptions.challenge).toString('base64url');
    const clientDataJson = {
        type: 'webauthn.create',
        origin: 'https://example.com',
        crossOrigin: false,
        challenge,
    };
    const clientData = new TextEncoder().encode(JSON.stringify(clientDataJson));

    const hash = crypto.createHash('sha256');
    hash.update(clientData);

    const requireUserVerification = ['required', 'preferred'].includes(registrationOptions.authenticatorSelection.userVerification);

    // TODO A method needs to be added to take the authenticator options
    // and convert them to a valid makeCredentialJSON options
    const makeCredentialJson = {
        authenticatorExtensions: '',
        clientDataHash: hash.digest('base64url'),
        credTypesAndPubKeyAlgs: registrationOptions.pubKeyCredParams.map(o => [o.type, o.alg]),
        excludeCredentials: [],
        requireResidentKey: registrationOptions.authenticatorSelection.requireResidentKey,
        requireUserPresence: !requireUserVerification,
        requireUserVerification,
        rp: registrationOptions.rp,
        user: {
            ...registrationOptions.user,
            id: userId,
            name: 'example',
            displayName: 'example',
        },
    };

    console.log('Create Credential Options')
    console.log(JSON.stringify(makeCredentialJson, undefined, 2));
    console.log('\n');

    const attestationJson = await prompt('Enter the Attestation Response JSON below followed by two empty lines:\n');
    const attestation = JSON.parse(attestationJson);

    attestation.origin = clientDataJson.origin;
    attestation.rawId = Uint8Array.from(Buffer.from(attestation.rawId, 'base64url')).buffer;
    attestation.response.clientDataJSON = clientData.buffer;

    const attestationExpectations = {
        challenge,
        origin: clientDataJson.origin,
        factor: "either",
    };
    
    const attestationResult = await f2l.attestationResult(attestation, attestationExpectations);

    console.log('Success!');
    console.log('public key', attestationResult.authnrData.get('credentialPublicKeyJwk'));
    console.log('counter', attestationResult.authnrData.get('counter'));
    console.log('---------------------\n');

    return [rawUserId, attestationResult];
}

async function doTestAssert([rawUserId, attestationResult]) {
    // console.log('test assert', Buffer.from(attestationResult.authnrData.get('credId')).toString('base64url'));
    const authnOptions = await f2l.assertionOptions();

    // TODO a method needs to be added to convert the assertion options
    // to a valid getAssertionOptions object
    const challenge = Buffer.from(authnOptions.challenge).toString('base64url');

    const clientDataJson = {
        type: 'webauthn.get',
        origin: 'https://example.com',
        crossOrigin: false,
        challenge,
    };
    const clientData = new TextEncoder().encode(JSON.stringify(clientDataJson));

    const hash = crypto.createHash('sha256');
    hash.update(clientData);

    const requireUserVerification = ['required', 'preferred'].includes(authnOptions.userVerification);

    const getAssertionOptions = {
        rpId: authnOptions.rpId,
        clientDataHash: hash.digest('base64url'),
        allowCredentialDescriptorList: [{
            type: 'public-key',
            id: Buffer.from(attestationResult.authnrData.get('credId')).toString('base64url'),
        }],
        requireUserPresence: !requireUserVerification,
        requireUserVerification,
    };

    console.log('Get Assertion Options');
    console.log(JSON.stringify(getAssertionOptions, undefined, 2));
    console.log('\n');

    while(true) {
        const assertionJson = await prompt('Enter the Assertion Response JSON below followed by two empty lines:\n');
        const assertion = JSON.parse(assertionJson);

        assertion.rawId = Uint8Array.from(Buffer.from(assertion.rawId, 'base64')).buffer;
        assertion.response.clientDataJSON = clientData.buffer;

        const assertionExpectations = {
            challenge,
            origin: clientDataJson.origin,
            factor: "either",
            publicKey: attestationResult.authnrData.get('credentialPublicKeyPem'),
            prevCounter: attestationResult.authnrData.get('counter'),
            userHandle: rawUserId,
            allowCredentials: getAssertionOptions.allowCredentialDescriptorList,
        };

        const authnResult = await f2l.assertionResult(assertion, assertionExpectations);

        console.log('Success!');
        console.log('signature', Buffer.from(authnResult.authnrData.get('sig')).toString('base64'));
        console.log('counter', authnResult.authnrData.get('counter'));
        console.log('---------------------\n');
    }
}

if (require.main === module) {
    Promise.resolve()
        .then(doTestCreate)
        .then(doTestAssert);
}
