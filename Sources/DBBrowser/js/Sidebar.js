import _ from 'lodash';
import React from 'react';
import { Text, View } from 'react-native';
import { Link } from '@react-navigation/native';

export default class Sidebar extends React.Component {
  render() {
    return (
      <View {...this.props}>
      <Link to='/table/test'>click</Link>
      </View>
    );
  }
}
