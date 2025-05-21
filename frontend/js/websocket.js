export default {
    init() {
        document.addEventListener('htmx:wsConnecting', () => console.log('Connecting WS...'));
        document.addEventListener('htmx:wsOpen', () => console.log('WS open'));
        document.addEventListener('htmx:wsClose', () => console.log('WS closed'));
        document.addEventListener('htmx:wsError', e => console.error('WS Error:', e.detail));
    },

    sendMessage(msg) {
        const wsElement = htmx.find('[ws-connect]');
        const socket = wsElement?.htmxWebSocket?.socket;
        if (socket) socket.send(msg);
        else console.error('WebSocket not connected');
    }
};
