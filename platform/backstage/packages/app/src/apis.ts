import {
  ScmIntegrationsApi,
  scmIntegrationsApiRef,
  ScmAuth,
} from '@backstage/integration-react';
import {
  AnyApiFactory,
  configApiRef,
  createApiFactory,
  discoveryApiRef,
  identityApiRef,
  oauthRequestApiRef,
} from '@backstage/core-plugin-api';
import { microsoftAuthApiRef } from '@backstage/core-plugin-api';
import { MicrosoftAuth } from '@backstage/plugin-auth-react';

export const apis: AnyApiFactory[] = [
  createApiFactory({
    api: scmIntegrationsApiRef,
    deps: { configApi: configApiRef },
    factory: ({ configApi }) => ScmIntegrationsApi.fromConfig(configApi),
  }),

  ScmAuth.createDefaultApiFactory(),

  createApiFactory({
    api: microsoftAuthApiRef,
    deps: {
      discoveryApi: discoveryApiRef,
      oauthRequestApi: oauthRequestApiRef,
      configApi: configApiRef,
    },
    factory: ({ discoveryApi, oauthRequestApi, configApi }) =>
      MicrosoftAuth.create({
        discoveryApi,
        oauthRequestApi,
        environment: configApi.getOptionalString('auth.environment'),
      }),
  }),
];
