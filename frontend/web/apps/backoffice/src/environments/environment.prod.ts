export const environment = {
  production: true,
  // Prod environment: always call the prod API gateway
  api_url: 'https://naavi-trails.fr/api/v1/',
  // Mapbox token should be provided via VITE_MAPBOX_TOKEN environment variable
  mapbox_token: '',
  turnstile_site_key: '',
};
