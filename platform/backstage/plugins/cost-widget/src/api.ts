import { ConfigApi } from '@backstage/core-plugin-api';

export interface ResourceCost {
  name: string;
  monthlyCost: number;
  type: string;
}

export interface ServiceCost {
  serviceId: string;
  monthlySpend: number;
  currency: string;
  trend30d: number[];
  topResources: ResourceCost[];
  lastUpdated: string;
}

export interface CostFixture {
  generatedAt: string;
  services: ServiceCost[];
}

let cache: { at: number; data: CostFixture } | null = null;
const TTL_MS = 5 * 60 * 1000;

export async function loadCostFixture(configApi: ConfigApi): Promise<CostFixture> {
  if (cache && Date.now() - cache.at < TTL_MS) {
    return cache.data;
  }

  // In production, swap this for a backend call to Azure Cost Management.
  // For now, the fixture is served from /fixtures/mock-costs.json by the dev server.
  const url =
    configApi.getOptionalString('costWidget.dataSource')?.replace(/^file:/, '') ??
    '/fixtures/mock-costs.json';

  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`cost-widget: failed to load ${url} (${res.status})`);
  }
  const data = (await res.json()) as CostFixture;
  cache = { at: Date.now(), data };
  return data;
}

export function formatCurrency(amount: number, currency: string): string {
  return new Intl.NumberFormat('en-CA', {
    style: 'currency',
    currency,
    maximumFractionDigits: 0,
  }).format(amount);
}
