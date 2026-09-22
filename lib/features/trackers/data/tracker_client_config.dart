const aniListClientId = String.fromEnvironment(
  'ANILIST_CLIENT_ID',
  defaultValue: '51298',
);
const aniListClientSecret = String.fromEnvironment('ANILIST_CLIENT_SECRET');

/// False in a build made without the secret. AniList login is then unavailable.
const aniListConfigured = aniListClientSecret != '';
