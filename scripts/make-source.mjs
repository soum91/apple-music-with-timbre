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
const description = 'Standalone MusicKit prototype. Apple Music authorization, library, search and playback; 10-band Timbre EQ for imported unprotected audio only. Subscription EQ is unavailable. Sign with a bundle ID registered for MusicKit. Device verification pending.';
const version = {
  version: '0.2.0', buildVersion: '2', date: new Date().toISOString(),
  localizedDescription: description, downloadURL, size: file.size, minOSVersion: '18.0'
};
console.log(JSON.stringify({
  name: 'Apple Music with Timbre', identifier: 'com.soum91.apple-music-with-timbre.source',
  subtitle: 'Apple Music player and Timbre audio tools', description,
  website: 'https://github.com/soum91/apple-music-with-timbre', sourceURL, iconURL,
  tintColor: '#6366F1', apps: [{
    name: 'Apple Music with Timbre', bundleIdentifier: 'com.soum91.applemusictimbre',
    developerName: 'soum91', subtitle: 'MusicKit player and local audio EQ',
    localizedDescription: description, iconURL, tintColor: '#6366F1', category: 'music',
    versions: [version], version: version.version, buildVersion: version.buildVersion,
    versionDate: version.date, versionDescription: description, downloadURL, size: file.size
  }], news: []
}, null, 2));
