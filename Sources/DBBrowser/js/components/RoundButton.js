import _ from 'lodash';
import React from 'react';
import { Text, Pressable } from 'react-native';

export default class RoundButton extends React.PureComponent {

	constructor(props) {
		super(props);

		this.state = {
			isHover: false,
		};
	}

	render() {

		const {
			title,
			style,
			titleStyle,
			hoverStyle,
			titleHoverStyle,
			onHoverIn,
			onHoverOut,
			...props
		} = this.props;

		const _onHoverIn = onHoverIn ?? (() => this.setState({ isHover: true }));
		const _onHoverOut = onHoverOut ?? (() => this.setState({ isHover: false }));

		const _hoverStyle = this.state.isHover ? hoverStyle : {};
		const _titleHoverStyle = this.state.isHover ? titleHoverStyle : {};

		return <Pressable
		onHoverIn={_onHoverIn}
		onHoverOut={_onHoverOut}
		style={{
			minWidth: 96,
			height: 32,
			borderRadius: 16,
			overflow: 'hidden',
			alignItems: 'center',
			justifyContent: 'center',
			backgroundColor: this.state.isHover ? '#1691E8' : '#2196F3',
			...style,
			..._hoverStyle
		}} {...props}>
			<Text style={{
				color: 'white',
				...titleStyle,
				..._titleHoverStyle
				}}>{title}</Text>
		</Pressable>;
	}
  }
  