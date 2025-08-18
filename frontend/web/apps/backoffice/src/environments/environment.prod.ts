import { getBaseUrl } from '@web/shared/util';

export const environment = {
  production: true,
  api_url: `${getBaseUrl()}/api`,
};
