import { createBackend } from '@backstage/backend-defaults';

const backend = createBackend();

// Serves the pre-built Backstage frontend from the /static directory
backend.add(import('@backstage/plugin-app-backend/alpha'));

// Auth — Microsoft Entra ID (Azure AD) provider for SSO
backend.add(import('@backstage/plugin-auth-backend'));
backend.add(import('@backstage/plugin-auth-backend-module-microsoft-provider'));
// Guest provider enabled only in non-production environments (set via config)
backend.add(import('@backstage/plugin-auth-backend-module-guest-provider'));

// Service catalog
backend.add(import('@backstage/plugin-catalog-backend/alpha'));
backend.add(import('@backstage/plugin-catalog-backend-module-github/alpha'));

// Software templates (scaffolder)
backend.add(import('@backstage/plugin-scaffolder-backend/alpha'));
backend.add(import('@backstage/plugin-scaffolder-backend-module-github'));

// TechDocs
backend.add(import('@backstage/plugin-techdocs-backend/alpha'));

// Kubernetes integration (shows workload status on entity pages)
backend.add(import('@backstage/plugin-kubernetes-backend/alpha'));

// Search
backend.add(import('@backstage/plugin-search-backend/alpha'));
backend.add(import('@backstage/plugin-search-backend-module-catalog/alpha'));
backend.add(import('@backstage/plugin-search-backend-module-techdocs/alpha'));

backend.start();
