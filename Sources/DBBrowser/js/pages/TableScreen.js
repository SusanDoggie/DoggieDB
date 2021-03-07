import _ from 'lodash';
import React from 'react';
import { Text, View, Image } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { Link } from '@react-navigation/native';

import birdImg from '../../asserts/bird.jpeg';

export default class TableScreen extends React.Component {
  render() {
    return (
      <View style={{ padding: 10 }}>
        <Image style={{ width: 96, height: 96 }} source={birdImg} />
        <Text style={{ fontWeight: 'bold' }}>TableScreen</Text>
      </View>
    );
  }
}
