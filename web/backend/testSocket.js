import {io} from 'socket.io-client'
const socket = io('http://localhost:8000', {
    transports: ['websocket', 'polling']
});
console.log('Connecting to server...');

socket.on('connect', () => {
    console.log('Connected to server:', socket.id);
    socket.emit('message', 'Hello from client!');
});

socket.on('connect_error', (err) => {
    console.error('Connection error:', err.message);
});
socket.on('connect_timeout', () => {
    console.error('Connection timed out.');
});

socket.on('newSos', (data) => {
    console.log('Received message:', data);
}); 

socket.on('updateRealTimeData', (data) => {
    console.log('Received message:', data);
}); 


socket.on('disconnect', () => {
    console.log('Disconnected from server');
});
