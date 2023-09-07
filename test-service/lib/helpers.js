function base64Buffer(base64) {
  return Uint8Array.from(Buffer.from(base64, 'base64url')).buffer;
}

function bufferBase64(buffer) {
  return Buffer.from(buffer).toString('base64url');
}

module.exports = {
  base64Buffer,
  bufferBase64,
};
