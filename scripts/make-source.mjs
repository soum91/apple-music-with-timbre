// Generate a FlareStore manifest only after an IPA and its real hosting URLs exist.
// Run from repository root: node scripts/make-source.mjs /path/build.ipa DOWNLOAD_URL SOURCE_URL ICON_URL
import { statSync } from 'node:fs';
const [ipa, downloadURL, sourceURL, iconURL] = process.argv.slice(2);
if (!ipa || !downloadURL || !sourceURL || !iconURL) {
  throw new Error('Provide IPA path, direct download URL, direct JSON URL and icon URL.');
}
for (const value of [downloadURL, sourceURL, iconURL]) {
  const url = new URL(value);
  if (url.protocol !== 'https:' || url.username || url.password) throw new Error('Use HTTPS URLs without credentials.');
}
const file = statSync(ipa);
if (!file.isFile() || file.size === 0) throw new Error('IPA must be a nonempty file.');
const description = 'Version 0.3.0 opens Apple Music free radio in a web player and tests whether Web Audio can reach its signal. Web EQ activates only after samples are detected. Safari playback is confirmed, but app web playback and audible EQ need device verification. Native MusicKit remains experimental; imported unprotected audio retains Timbre EQ.';
const version = {
  version: '0.3.0', buildVersion: '3', date: new Date().toISOString(),
  localizedDescription: description, downloadURL, size: file.size, minOSVersion: '18.0'
};
console.log(JSON.stringify({
  name: 'Apple Music with Timbre', identifier: 'com.soum91.apple-music-with-timbre.source',
  subtitle: 'Apple Music web radio and Timbre audio test', description,
  website: 'https://github.com/soum91/apple-music-with-timbre', sourceURL, iconURL,
  tintColor: '#6366F1', apps: [{
    name: 'Apple Music with Timbre', bundleIdentifier: 'com.soum91.applemusictimbre',
    developerName: 'soum91', subtitle: 'Apple Music web radio and audio access test',
    localizedDescription: description, iconURL, tintColor: '#6366F1', category: 'music',
    versions: [version], version: version.version, buildVersion: version.buildVersion,
    versionDate: version.date, versionDescription: description, downloadURL, size: file.size
  }], news: []
}, null, 2));
