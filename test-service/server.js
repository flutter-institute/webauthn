const bodyParser = require('body-parser');
const eckey = require('ec-key');
const express = require('express');

const { WebException } = require('./lib/exceptions');
const WebauthnHandler = require('./lib/handler');
const { bufferBase64 } = require('./lib/helpers');

const handler = new WebauthnHandler();
const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use((req, res, next) => {
  if (req.query['userId']) {
    req.userId = req.query['userId'].replace('=', '').trim();
  }
  next();
});
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status ?? 500).json({ success: false, error: err.message });
});

app.get('/attestation', async (req, res) => {
  const options = await handler.createAttestationOptions();
  console.log('attestation options', options);

  res.json({ success: true, options });
});

app.post('/attestation', async (req, res) => {
  if (!req.userId) {
    throw new WebException(400, 'Invalid userId query parameter');
  }
  console.log('attestation response', req.body);

  const result = await handler.verifyAttestationResponse(req.userId, req.body);

  const keyData = result.get('credentialPublicKeyJwk');
  const key = eckey(keyData);
  console.log('Attestation Success!');
  console.log('public key', keyData);
  console.log(key.toString('pem'));
  res.json({ success: true });
});

app.get('/assertion', async (req, res) => {
  if (!req.userId) {
    throw new WebException(400, 'Invalid userId query parameter');
  }

  const options = await handler.createAssertionOptions(req.userId);
  console.log('assertion options', options);

  res.json({success: true, options });
});

app.post('/assertion', async(req, res) => {
  if (!req.userId) {
    throw new WebException(400, 'Invalid userId query parameter');
  }
  console.log('assertion response', req.body);

  const result = await handler.verifyAssertionResponse(req.userId, req.body);
  console.log('Assertion Success!');
  console.log('signature', bufferBase64(result.get('sig')));
  console.log('counter', result.get('counter'));
  res.json({ success: true });
});

app.listen(port, () => {
  console.log(`Listening on port ${port}`);
});
