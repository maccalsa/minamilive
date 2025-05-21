import stateManager from './stateManager.js';
import apiClient from './apiClient.js';
import websocket from './websocket.js';

window.App = () => ({
    state: {
        user: { name: '' },
        preferences: { theme: 'light' },
        sessionExpired: false
    },

    async init() {
        websocket.init();
        this.state.preferences.theme = await stateManager.loadPreferences();
        this.state.user = await stateManager.loadUserData() || { name: '' };
        await this.checkSession();
        this.monitorSession();
    },

    async checkSession() {
        const res = await apiClient.getUser();
        if (res.status === 401) {
            this.handleSessionExpiry();
        } else {
            this.state.user = await res.json();
            await stateManager.saveUserData(this.state.user);
            this.state.sessionExpired = false;
        }
    },

    monitorSession() {
        setInterval(() => this.checkSession(), 30000);
    },

    async login() {
        const res = await apiClient.login();
        if (res.ok) await this.checkSession();
    },

    async logout() {
        await apiClient.logout();
        this.handleSessionExpiry();
    },

    async toggleTheme() {
        this.state.preferences.theme = this.state.preferences.theme === 'light' ? 'dark' : 'light';
        await stateManager.savePreferences(this.state.preferences.theme);
    },

    handleSessionExpiry() {
        this.state.user = { name: '' };
        this.state.sessionExpired = true;
        stateManager.clearUserData();
    }
});
