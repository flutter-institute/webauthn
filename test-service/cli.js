const readline = require('readline');

const { bufferBase64 } = require('./lib/helpers');
const WebauthnHandler = require('./lib/handler');

const handler = new WebauthnHandler();

async function prompt(query, numNewline = 1) {
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
                if (emptyLineCount == numNewline) {
                    finish();
                }
            } else {
                lines.push(line);
            }
        })
    });
}

async function doTestCreate() {
    const registrationOptions = await handler.createAttestationOptions();
    const userId = registrationOptions.user.id;

    const challenge = registrationOptions.challenge;
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

    const attestationJson = await prompt('Enter the Attestation Response JSON below followed by two empty lines:\n', 2);
    const attestation = JSON.parse(attestationJson);

    const attestationResult = await handler.verifyAttestationResponse(userId, attestation);

    console.log('Success!');
    console.log('public key', attestationResult.authnrData.get('credentialPublicKeyJwk'));
    console.log('counter', attestationResult.authnrData.get('counter'));
    console.log('---------------------\n');

    return [userId, attestationResult];
}

async function doTestAssert([userId, attestationResult]) {
    const authnOptions = await handler.createAssertionOptions(userId);

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

    const assertionJson = await prompt('Enter the Assertion Response JSON below followed by two empty lines:\n', 2);
    const assertion = JSON.parse(assertionJson);

    const authnResult = await handler.verifyAssertionResponse(userId, assertion);

    console.log('Success!');
    console.log('signature', bufferBase64(authnResult.get('sig')));
    console.log('counter', authnResult.get('counter'));
    console.log('---------------------\n');
    await prompt('Press enter to continue\n');
}

if (require.main === module) {
    Promise.resolve()
        .then(doTestCreate)
        .then(async result => {
            while (true) {
                await doTestAssert(result);
            }
        });
}
