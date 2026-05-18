import React, { useEffect, useState } from 'react';
import { useEntity } from '@backstage/plugin-catalog-react';
import { useApi, configApiRef } from '@backstage/core-plugin-api';
import {
  Card,
  CardContent,
  CardHeader,
  Chip,
  Grid,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Typography,
  makeStyles,
} from '@material-ui/core';
import { Progress, EmptyState, InfoCard } from '@backstage/core-components';
import { loadCostFixture, ServiceCost, formatCurrency } from './api';

const useStyles = makeStyles(theme => ({
  bigNumber: {
    fontSize: '3rem',
    fontWeight: 600,
    lineHeight: 1.1,
    color: theme.palette.text.primary,
  },
  per: {
    fontSize: '1rem',
    color: theme.palette.text.secondary,
    marginLeft: theme.spacing(1),
  },
  beta: {
    marginLeft: theme.spacing(1),
  },
  sparkline: {
    width: '100%',
    height: 80,
  },
  smallLabel: {
    color: theme.palette.text.secondary,
    fontSize: '0.75rem',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
}));

function Sparkline({ data }: { data: number[] }) {
  const classes = useStyles();
  if (!data.length) return null;
  const min = Math.min(...data);
  const max = Math.max(...data);
  const range = max - min || 1;
  const w = 600;
  const h = 80;
  const pts = data
    .map((v, i) => {
      const x = (i / (data.length - 1)) * w;
      const y = h - ((v - min) / range) * (h - 4) - 2;
      return `${x.toFixed(1)},${y.toFixed(1)}`;
    })
    .join(' ');
  return (
    <svg className={classes.sparkline} viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none">
      <polyline
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinejoin="round"
        strokeLinecap="round"
        points={pts}
      />
    </svg>
  );
}

export const CostTab = () => {
  const classes = useStyles();
  const { entity } = useEntity();
  const configApi = useApi(configApiRef);
  const [state, setState] = useState<{ loading: boolean; data?: ServiceCost; error?: string }>({
    loading: true,
  });

  const serviceId =
    entity.metadata.annotations?.['costWidget.serviceId'] ?? entity.metadata.name;

  useEffect(() => {
    let cancelled = false;
    loadCostFixture(configApi)
      .then(fix => {
        if (cancelled) return;
        const match = fix.services.find(s => s.serviceId === serviceId);
        setState({ loading: false, data: match });
      })
      .catch(err => !cancelled && setState({ loading: false, error: String(err) }));
    return () => {
      cancelled = true;
    };
  }, [configApi, serviceId]);

  if (state.loading) return <Progress />;
  if (state.error)
    return (
      <EmptyState
        missing="data"
        title="Cost data unavailable"
        description={state.error}
      />
    );
  if (!state.data)
    return (
      <EmptyState
        missing="data"
        title="No cost data for this service"
        description="The service may be too new, or the cost fixture has not been refreshed yet."
      />
    );

  const { monthlySpend, currency, trend30d, topResources, lastUpdated } = state.data;

  return (
    <Grid container spacing={3}>
      <Grid item xs={12} md={6}>
        <Card>
          <CardHeader
            title="Azure Cost"
            subheader={`Last updated ${new Date(lastUpdated).toLocaleString('en-CA')}`}
            action={
              <Chip
                label="Beta · mocked data"
                color="secondary"
                size="small"
                className={classes.beta}
              />
            }
          />
          <CardContent>
            <Typography component="span" className={classes.bigNumber}>
              {formatCurrency(monthlySpend, currency)}
            </Typography>
            <Typography component="span" className={classes.per}>
              / month
            </Typography>
            <div className={classes.smallLabel} style={{ marginTop: 12 }}>
              30-day trend
            </div>
            <Sparkline data={trend30d} />
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} md={6}>
        <InfoCard title="Top resources by cost">
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Resource</TableCell>
                <TableCell>Type</TableCell>
                <TableCell align="right">Monthly</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {topResources.map(r => (
                <TableRow key={r.name}>
                  <TableCell>{r.name}</TableCell>
                  <TableCell>
                    <Typography variant="body2" color="textSecondary">
                      {r.type}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    {formatCurrency(r.monthlyCost, currency)}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </InfoCard>
      </Grid>
    </Grid>
  );
};
