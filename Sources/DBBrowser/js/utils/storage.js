import _ from 'lodash';
import { EJSON } from 'bson';

function storageAvailable(type) {
	var storage;
	try {
		storage = window[type];
		var x = '__storage_test__';
		storage.setItem(x, x);
		storage.removeItem(x);
		return true;
	}
	catch(e) {
		return e instanceof DOMException && (
			// everything except Firefox
			e.code === 22 ||
			// Firefox
			e.code === 1014 ||
			// test name field too, because code might not be present
			// everything except Firefox
			e.name === 'QuotaExceededError' ||
			// Firefox
			e.name === 'NS_ERROR_DOM_QUOTA_REACHED') &&
			// acknowledge QuotaExceededError only if there's something already stored
			(storage && storage.length !== 0);
	}
}

const defaultStorageOptions = {
	persistent: false,
}

function resolveStorage(type) {
    if (global.window && storageAvailable(type)) return window[type];
}

const sessionStorage = resolveStorage('sessionStorage');
const localStorage = resolveStorage('localStorage');

class Storage {

	keys() {
		return _.uniq([Object.keys(sessionStorage), Object.keys(localStorage)].flat());
	}
	
	clear() {
		localStorage?.clear();
		sessionStorage?.clear();
	}
	
	removeItem(key) {
		localStorage?.removeItem(key);
		sessionStorage?.removeItem(key);
	}

	getItem(key) {
		const data = sessionStorage?.getItem(key) ?? localStorage?.getItem(key);
		return _.isNil(data) ? undefined : EJSON.parse(data);
	}

	setItem(key, value, options = defaultStorageOptions) {
		const storage = options.persistent ? localStorage : sessionStorage;
		storage?.setItem(key, EJSON.stringify(value));
	}
}

export default new Storage();