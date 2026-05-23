import React, { PropsWithChildren } from 'react';
import { makeStyles } from '@material-ui/core';
import HomeIcon from '@material-ui/icons/Home';
import LibraryBooks from '@material-ui/icons/LibraryBooks';
import CreateComponentIcon from '@material-ui/icons/AddCircleOutline';
import ExtensionIcon from '@material-ui/icons/Extension';
import MapIcon from '@material-ui/icons/MyLocation';
import LayersIcon from '@material-ui/icons/Layers';
import {
  Sidebar,
  sidebarConfig,
  SidebarDivider,
  SidebarGroup,
  SidebarItem,
  SidebarPage,
  SidebarScrollWrapper,
  SidebarSpace,
  useSidebarOpenState,
  Link,
} from '@backstage/core-components';
import { NavLink } from 'react-router-dom';
import { SearchContextProvider } from '@backstage/plugin-search-react';
import { SidebarSearchModal } from '@backstage/plugin-search';
import {
  Settings as SidebarSettings,
  UserSettingsSignInAvatar,
} from '@backstage/plugin-user-settings';
import { SidebarLogo } from './SidebarLogo';

const useSidebarLogoStyles = makeStyles({
  root: {
    width: sidebarConfig.drawerWidthClosed,
    height: 3 * sidebarConfig.iconContainerHeight,
    display: 'flex',
    flexFlow: 'row nowrap',
    alignItems: 'center',
    marginBottom: -14,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    overflow: 'hidden',
    whiteSpace: 'nowrap',
    paddingLeft: 6,
  },
  link: {
    color: 'inherit',
  },
});

export const Root = ({ children }: PropsWithChildren<{}>) => (
  <SidebarPage>
    <Sidebar>
      <SidebarLogo />
      <SearchContextProvider>
        <SidebarGroup label="Search" icon={<HomeIcon />} to="/search">
          <SidebarSearchModal />
        </SidebarGroup>
      </SearchContextProvider>
      <SidebarDivider />
      <SidebarGroup label="Menu" icon={<HomeIcon />}>
        <SidebarItem icon={HomeIcon} to="catalog" text="Catalog" />
        <SidebarItem icon={CreateComponentIcon} to="create" text="Create" />
        <SidebarItem icon={LayersIcon} to="api-docs" text="APIs" />
        <SidebarItem icon={LibraryBooks} to="docs" text="Docs" />
        <SidebarScrollWrapper>
          <SidebarItem icon={MapIcon} to="catalog-import" text="Import" />
        </SidebarScrollWrapper>
      </SidebarGroup>
      <SidebarSpace />
      <SidebarDivider />
      <SidebarGroup
        label="Settings"
        icon={<ExtensionIcon />}
        to="/settings"
      >
        <SidebarSettings />
        <UserSettingsSignInAvatar />
      </SidebarGroup>
    </Sidebar>
    {children}
  </SidebarPage>
);
