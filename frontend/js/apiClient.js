export default {
    async login() {
        return fetch('/api/login', { credentials: 'include' });
    },

    async logout() {
        return fetch('/api/logout', { credentials: 'include' });
    },

    async getUser() {
        return fetch('/api/me', { credentials: 'include' });
    }
};
