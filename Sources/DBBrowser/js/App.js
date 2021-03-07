import _ from 'lodash';
import React from 'react';
import { Text, View, Image } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import Sidebar from './Sidebar';

import TableScreen from './pages/TableScreen';

const Stack = createStackNavigator();

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
      <View style={{ flexDirection: 'row', flex: 1 }}>
        <Sidebar style={{ width: 256 }} />
        <NavigationContainer linking={linking} fallback={<Text>Loading...</Text>}>
          <Stack.Navigator>
            <Stack.Screen name="Table" component={TableScreen} />
          </Stack.Navigator>
        </NavigationContainer>
      </View>
    );
  }
}
