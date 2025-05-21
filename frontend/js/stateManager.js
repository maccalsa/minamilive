const db = new Dexie('AppStateDB');
db.version(1).stores({
    preferences: '&key, value',
    userData: '&key, value'
});

export default {
    async loadPreferences() {
        return (await db.preferences.get('theme'))?.value || 'light';
    },

    async savePreferences(theme) {
        await db.preferences.put({ key: 'theme', value: theme });
    },

    async loadUserData() {
        return (await db.userData.get('user'))?.value || null;
    },

    async saveUserData(user) {
        await db.userData.put({ key: 'user', value: JSON.parse(JSON.stringify(user)) });
    },

    async clearUserData() {
        await db.userData.clear();
    }
};