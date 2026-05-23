import React from 'react';
import { makeStyles } from '@material-ui/core';
import { sidebarConfig, Link } from '@backstage/core-components';
import { useSidebarOpenState } from '@backstage/core-components';

const useStyles = makeStyles({
  root: {
    width: sidebarConfig.drawerWidthClosed,
    height: 3 * sidebarConfig.iconContainerHeight,
    display: 'flex',
    flexFlow: 'row nowrap',
    alignItems: 'center',
    marginBottom: -14,
  },
  logoFull: {
    width: 'auto',
    height: 28,
    filter: 'invert(1)',
  },
  logoIcon: {
    width: 28,
    height: 28,
    filter: 'invert(1)',
  },
  title: {
    fontSize: 16,
    fontWeight: 700,
    color: '#ffffff',
    paddingLeft: 8,
    whiteSpace: 'nowrap',
  },
  link: {
    color: 'inherit',
    display: 'flex',
    alignItems: 'center',
    paddingLeft: 12,
  },
});

export const SidebarLogo = () => {
  const classes = useStyles();
  const { isOpen } = useSidebarOpenState();

  return (
    <div className={classes.root}>
      <Link to="/" underline="none" className={classes.link}>
        <span style={{ fontSize: 22 }}>⬡</span>
        {isOpen && (
          <span className={classes.title}>Meridian Pay</span>
        )}
      </Link>
    </div>
  );
};
