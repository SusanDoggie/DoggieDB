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

async function resolveStorage(type) {
    if (global.window && storageAvailable(type)) {
		return type == 'sessionStorage' ? sessionStorage : localStorage;
	}
}

class Storage {

	get keys() {
		return Promise.all([
			resolveStorage('sessionStorage').then(storage => Object.keys(storage)),
			resolveStorage('localStorage').then(storage => Object.keys(storage)),
		]).then((keys) => _.uniq(keys.flat()));
	}
	
	async clear() {
		const _sessionStorage = await resolveStorage('sessionStorage');
		const _localStorage = await resolveStorage('localStorage');
		_localStorage?.clear();
		_sessionStorage?.clear();
	}
	
	async removeItem(key) {
		const _sessionStorage = await resolveStorage('sessionStorage');
		const _localStorage = await resolveStorage('localStorage');
		_localStorage?.removeItem(key);
		_sessionStorage?.removeItem(key);
	}

	async getItem(key) {
		const _sessionStorage = await resolveStorage('sessionStorage');
		const _localStorage = await resolveStorage('localStorage');
		const data = _sessionStorage?.getItem(key) ?? _localStorage?.getItem(key);
		return _.isNil(data) ? undefined : EJSON.parse(data);
	}

	async setItem(key, value, options = defaultStorageOptions) {
		const _storage = await resolveStorage(options.persistent ? 'localStorage' : 'sessionStorage');
		if (_storage) {
			_storage.setItem(key, EJSON.stringify(value));
		}
	}
}

export default new Storage();