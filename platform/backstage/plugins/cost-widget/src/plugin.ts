import {
  createPlugin,
  createRoutableExtension,
} from '@backstage/core-plugin-api';

export const costWidgetPlugin = createPlugin({
  id: 'cost-widget',
});

export const EntityCostTab = costWidgetPlugin.provide(
  createRoutableExtension({
    name: 'EntityCostTab',
    component: () => import('./CostTab').then(m => m.CostTab),
    mountPoint: {
      id: 'plugin.cost-widget.tab',
    } as any,
  }),
);
