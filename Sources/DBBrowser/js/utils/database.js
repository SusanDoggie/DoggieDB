import React from 'react';

function createDatabase() {
	
	const data = {};
	
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
