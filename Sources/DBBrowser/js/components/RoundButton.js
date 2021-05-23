import _ from 'lodash';
import React from 'react';
import { View, TouchableWithoutFeedback, Text } from 'react-native';

export default class RoundButton extends React.PureComponent {

	render() {

		const {
			title,
			onPress,
			style,
			titleStyle,
			...props
		} = this.props;

	  return <TouchableWithoutFeedback onPress={onPress}>
	  	<View style={{
			  minWidth: 96,
			  height: 32,
			  borderRadius: 16,
			  overflow: 'hidden',
			  alignItems: 'center',
			  justifyContent: 'center',
			  backgroundColor: '#2196F3',
			  ...style
			}} {...props}>
		  <Text style={{
			  color: 'white',
			  ...titleStyle
			}}>{title}</Text>
		</View>
	  </TouchableWithoutFeedback>;
	}
  }
  