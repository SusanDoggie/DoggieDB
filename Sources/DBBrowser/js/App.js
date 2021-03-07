import _ from 'lodash';
import React from 'react';
import { Text } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createDrawerNavigator } from '@react-navigation/drawer';

import TableScreen from './pages/TableScreen';

const Drawer = createDrawerNavigator();

const linking = {
  prefixes: [
  ],
  config: {
    screens: {
      Table: 'table/:table',
    },
  },
};

export default class App extends React.Component {
  render() {
    return (
      <NavigationContainer linking={linking} fallback={<Text>Loading...</Text>}>
        <Drawer.Navigator
          openByDefault
          drawerType='permanent'
          overlayColor='transparent'>
          <Drawer.Screen name="Table" component={TableScreen} />
        </Drawer.Navigator>
      </NavigationContainer>
    );
  }
}
