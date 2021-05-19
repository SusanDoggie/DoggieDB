import _ from 'lodash';
import React from 'react';

function createSocket() {
	if (_.isNil(global.WebSocket) || _.isNil(global.location)) return;
	return location.protocol == 'http:' ? new WebSocket(`ws://${location.host}/ws`) : new WebSocket(`wss://${location.host}/ws`);
}

function createDatabase() {

	const socket = createSocket();
	
	class Database {

		connect() {
			
		}
	}
	
	return new Database();
}

export const DatabaseContext = React.createContext(createDatabase());

export function withDatabase(Component) {
	return (props) => <Component database={React.useContext(DatabaseContext)} {...props} />;
}
