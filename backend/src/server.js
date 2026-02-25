require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const authRoutes = require('./routes/auth');
const portfolioRoutes = require('./routes/portfolios');
const transactionRoutes = require('./routes/transactions');
const adminRoutes = require('./routes/admin');
const newsRoutes = require('./routes/news');

const app = express();
const http = require('http');
const server = http.createServer(app);
const { Server } = require('socket.io');

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

// Start Real-time Price Engine
const PriceEngine = require('./services/PriceEngine');
PriceEngine.init(io);

app.use(helmet());
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));
app.use(morgan('dev'));

// Static files for uploaded images
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

app.get('/health', (_, res) => res.json({ status: 'ok' }));

// Attach io to req so routes can use it
app.use((req, res, next) => {
  req.io = io;
  next();
});

app.use('/auth', authRoutes);
app.use('/portfolios', portfolioRoutes);
app.use('/transactions', transactionRoutes);
app.use('/admin', adminRoutes);
app.use('/news', newsRoutes);

// Socket.io connection handling
io.on('connection', (socket) => {
  console.log('A user connected:', socket.id);
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// 404
app.use((req, res) => res.status(404).json({ message: 'Not found' }));

// Error handler
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ message: 'Server error' });
});

const port = 8081;
server.listen(port, () => {
  console.log(`investcow backend running on http://localhost:${port}`);
});

