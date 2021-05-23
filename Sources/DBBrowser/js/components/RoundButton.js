import _ from 'lodash';
import React from 'react';

import Button from './Button';

export default class RoundButton extends React.PureComponent {

	render() {

		const {
			style,
			...props
		} = this.props;

		return <Button
		style={{
			minWidth: 96,
			height: 32,
			borderRadius: 16,
			overflow: 'hidden',
			...style
		}}
		{...props} />;
	}
  }
  