import _ from 'lodash';
import React from 'react';
import { v4 as uuidv4 } from 'uuid';
import { EJSON } from 'bson';

function createSocket() {
	if (_.isNil(global.WebSocket) || _.isNil(global.location)) return;
	return location.protocol == 'http:' ? new WebSocket(`ws://${location.host}/ws`) : new WebSocket(`wss://${location.host}/ws`);
}

function createDatabase() {

	const socket = createSocket();
	if (!socket) return;
	
	const callbacks = {};
	
	let isopen = false;
	
	socket.onopen = () => isopen = true;
	socket.onclose = () => isopen = false;
	socket.onmessage = ({data}) => {
		const result = EJSON.parse(data);
		if (result['success']) {
			callbacks[result.token]?.resolve(result['data']);
		} else {
			callbacks[result.token]?.reject(new Error(result['error']));
		}
		delete callbacks[result.token];
	}

	function socket_run(data) {
		if (!isopen) throw new Error('socket not connected');
		data.token = uuidv4();
		socket.send(EJSON.stringify(data));
		return new Promise((resolve, reject) => callbacks[data.token] = { resolve, reject });
	}
	
	class Database {

		connect(url) {
			return socket_run({ action: 'connect', url });
		}
		
		runSQLCommand(sql) {
			return socket_run({ action: 'runCommand', type: 'sql', command: sql });
		}
		
		runMongoCommand(command) {
			return socket_run({ action: 'runCommand', type: 'mongo', command: command });
		}
	}
	
	return new Database();
}

export const DatabaseContext = React.createContext(createDatabase());

export function withDatabase(Component) {
	return (props) => <Component database={React.useContext(DatabaseContext)} {...props} />;
}
