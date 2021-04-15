import React from 'react';
import { AppRegistry } from 'react-native';
import { StaticRouter } from 'react-router-dom';
import ReactDOMServer from 'react-dom/server';
import App from './App';

global.render = function(location) {

	const context = {};
	
	class Main extends React.Component {
		render() {
			return <StaticRouter location={location} context={context}><App /></StaticRouter>;
		}
	}
	
	AppRegistry.registerComponent('App', () => Main);
	const { element, getStyleElement } = AppRegistry.getApplication('App');

	context.html = ReactDOMServer.renderToString(element);
	context.css = ReactDOMServer.renderToStaticMarkup(getStyleElement());
	
	return context;
	;
}