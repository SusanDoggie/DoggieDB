import _ from 'lodash';
import React from 'react';
import { Text, View } from 'react-native';

export default class App extends React.Component {
  render() {
    return (
      <View style={{ padding: 10 }}>
        <Text style={{ fontWeight: 'bold' }}>Hello, world!</Text>
      </View>
    );
  }
}
