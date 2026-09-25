const aniListClientId = String.fromEnvironment(
  'ANILIST_CLIENT_ID',
  defaultValue: '51298',
);
const aniListClientSecret = String.fromEnvironment('ANILIST_CLIENT_SECRET');

/// False in a build made without the secret. AniList login is then unavailable.
const aniListConfigured = aniListClientSecret != '';

// MyAnimeList. The id comes from the app's registration; like AniList's secret
// it is passed in at build time and never kept in the source.
const malClientId = String.fromEnvironment('MAL_CLIENT_ID');
const malClientSecret = String.fromEnvironment('MAL_CLIENT_SECRET');

/// Sign-in for an app on a person's own device is PKCE, which needs no secret.
/// The console may show the id again as the "secret", or none at all, so a
/// secret that is empty or equal to the id is not sent.
const malSendsSecret = malClientSecret != '' && malClientSecret != malClientId;

/// False in a build made without the MyAnimeList client id. Login is then unavailable.
const malConfigured = malClientId != '';
