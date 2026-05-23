import React from 'react';
import { Navigate, Route } from 'react-router-dom';
import { apiDocsPlugin, ApiExplorerPage } from '@backstage/plugin-api-docs';
import {
  CatalogEntityPage,
  CatalogIndexPage,
  catalogPlugin,
} from '@backstage/plugin-catalog';
import {
  CatalogImportPage,
  catalogImportPlugin,
} from '@backstage/plugin-catalog-import';
import { ScaffolderPage, scaffolderPlugin } from '@backstage/plugin-scaffolder';
import { orgPlugin } from '@backstage/plugin-org';
import { SearchPage } from '@backstage/plugin-search';
import {
  TechDocsIndexPage,
  TechDocsReaderPage,
  techdocsPlugin,
} from '@backstage/plugin-techdocs';
import { TechDocsAddons } from '@backstage/plugin-techdocs-react';
import { UserSettingsPage } from '@backstage/plugin-user-settings';
import { apis } from './apis';
import { Root } from './components/Root';
import {
  AlertDisplay,
  OAuthRequestDialog,
  SignInPage,
} from '@backstage/core-components';
import { createApp } from '@backstage/app-defaults';
import { AppRouter, FlatRoutes } from '@backstage/core-app-api';
import {
  microsoftAuthApiRef,
  ApiRef,
} from '@backstage/core-plugin-api';
import {
  EntityLayout,
  EntitySwitch,
  EntityOrphanWarning,
  EntityProcessingErrorsPanel,
  hasCatalogProcessingErrors,
  isOrphan,
} from '@backstage/plugin-catalog';
import {
  isKubernetesAvailable,
} from '@backstage/plugin-catalog-react';
import {
  EntityAboutCard,
  EntityDependsOnComponentsCard,
  EntityDependsOnResourcesCard,
  EntityHasSubcomponentsCard,
  EntityLinksCard,
} from '@backstage/plugin-catalog';
import { EntityCatalogGraphCard } from '@backstage/plugin-catalog-graph';
import { EntityCostTab } from '@meridianpay/plugin-cost-widget';

// ─── Entity page layout ──────────────────────────────────────────────────────

const defaultEntityPage = (
  <EntityLayout>
    <EntityLayout.Route path="/" title="Overview">
      <EntitySwitch>
        <EntitySwitch.Case if={isOrphan}>
          <EntityOrphanWarning />
        </EntitySwitch.Case>
        <EntitySwitch.Case if={hasCatalogProcessingErrors}>
          <EntityProcessingErrorsPanel />
        </EntitySwitch.Case>
      </EntitySwitch>
      <EntityAboutCard variant="gridItem" />
      <EntityLinksCard />
    </EntityLayout.Route>

    <EntityLayout.Route path="/cost" title="Cost">
      <EntityCostTab />
    </EntityLayout.Route>

    <EntityLayout.Route path="/dependencies" title="Dependencies">
      <EntityDependsOnComponentsCard variant="gridItem" />
      <EntityDependsOnResourcesCard variant="gridItem" />
    </EntityLayout.Route>

    <EntityLayout.Route path="/diagram" title="Diagram">
      <EntityCatalogGraphCard variant="gridItem" height={400} />
    </EntityLayout.Route>
  </EntityLayout>
);

const serviceEntityPage = (
  <EntityLayout>
    <EntityLayout.Route path="/" title="Overview">
      <EntityAboutCard variant="gridItem" />
      <EntityLinksCard />
    </EntityLayout.Route>

    <EntityLayout.Route path="/cost" title="Cost">
      <EntityCostTab />
    </EntityLayout.Route>

    <EntityLayout.Route path="/dependencies" title="Dependencies">
      <EntityDependsOnComponentsCard variant="gridItem" />
      <EntityHasSubcomponentsCard variant="gridItem" />
    </EntityLayout.Route>

    <EntityLayout.Route path="/diagram" title="Diagram">
      <EntityCatalogGraphCard variant="gridItem" height={400} />
    </EntityLayout.Route>
  </EntityLayout>
);

const entityPage = (
  <EntitySwitch>
    <EntitySwitch.Case if={e => e.spec?.type === 'service'}>
      {serviceEntityPage}
    </EntitySwitch.Case>
    <EntitySwitch.Case>{defaultEntityPage}</EntitySwitch.Case>
  </EntitySwitch>
);

// ─── App ─────────────────────────────────────────────────────────────────────

const app = createApp({
  apis,
  plugins: [
    apiDocsPlugin,
    catalogPlugin,
    catalogImportPlugin,
    scaffolderPlugin,
    orgPlugin,
    techdocsPlugin,
  ],
  components: {
    SignInPage: props => (
      <SignInPage
        {...props}
        auto
        provider={{
          id: 'microsoft-auth-provider',
          title: 'Microsoft',
          message: 'Sign in using your Microsoft account',
          apiRef: microsoftAuthApiRef as ApiRef<any>,
        }}
      />
    ),
  },
  bindRoutes({ bind }) {
    bind(catalogPlugin.externalRoutes, {
      createComponent: scaffolderPlugin.routes.root,
      viewTechDoc: techdocsPlugin.routes.docRoot,
      createFromTemplate: scaffolderPlugin.routes.selectedTemplate,
    });
    bind(apiDocsPlugin.externalRoutes, {
      registerApi: catalogImportPlugin.routes.importPage,
    });
    bind(scaffolderPlugin.externalRoutes, {
      registerComponent: catalogImportPlugin.routes.importPage,
      viewTechDoc: techdocsPlugin.routes.docRoot,
    });
    bind(orgPlugin.externalRoutes, {
      catalogIndex: catalogPlugin.routes.catalogIndex,
    });
  },
});

export default app.createRoot(
  <>
    <AlertDisplay />
    <OAuthRequestDialog />
    <AppRouter>
      <Root>
        <FlatRoutes>
          <Route path="/" element={<Navigate to="catalog" />} />
          <Route path="/catalog" element={<CatalogIndexPage />} />
          <Route
            path="/catalog/:namespace/:kind/:name"
            element={<CatalogEntityPage />}
          >
            {entityPage}
          </Route>
          <Route path="/docs" element={<TechDocsIndexPage />} />
          <Route
            path="/docs/:namespace/:kind/:name/*"
            element={<TechDocsReaderPage />}
          >
            <TechDocsAddons />
          </Route>
          <Route path="/create" element={<ScaffolderPage />} />
          <Route path="/api-docs" element={<ApiExplorerPage />} />
          <Route path="/catalog-import" element={<CatalogImportPage />} />
          <Route path="/search" element={<SearchPage />} />
          <Route path="/settings" element={<UserSettingsPage />} />
        </FlatRoutes>
      </Root>
    </AppRouter>
  </>,
);
