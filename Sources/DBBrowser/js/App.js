import _ from 'lodash';
import React from 'react';
import { Text, View, Image } from 'react-native';

import birdImg from '../asserts/bird.jpeg';

export default class App extends React.Component {
  render() {
    return (
      <View style={{ padding: 10 }}>
        <Image style={{ width: 96, height: 96 }} source={birdImg} />
        <Text style={{ fontWeight: 'bold' }}>Hello, world!</Text>
      </View>
    );
  }
}
