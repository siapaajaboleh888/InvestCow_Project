require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const logger = require('./utils/logger');

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
    origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*',
    methods: ['GET', 'POST'],
  },
});

// Start Real-time Price Engine
const PriceEngine = require('./services/PriceEngine');
PriceEngine.init(io);

// RATE LIMITING
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 250, // Limit each IP to 250 requests per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Too many requests, please try again later.' },
});

const authLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 20, // Limit each IP to 20 attempts per hour for sensitive routes
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Auth limit reached. Please wait an hour.' },
});

app.use(helmet({
  crossOriginResourcePolicy: false,
}));

// Apply global rate limit to all routes
app.use(globalLimiter);

app.use(cors({
  origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*'
}));

app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ limit: '5mb', extended: true }));

// Dynamic logging based on environment
if (process.env.NODE_ENV === 'production') {
  app.use(morgan('combined', { stream: { write: (message) => logger.info(message.trim()) } }));
} else {
  app.use(morgan('dev'));
}

// Static assets
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

app.get('/', (_, res) => res.json({
  name: 'InvestCow API',
  version: '1.1.0-prod',
  status: 'active',
  environment: process.env.NODE_ENV || 'development'
}));

app.get('/health', (_, res) => {
  const healthCheck = {
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    memory_usage: process.memoryUsage(),
  };
  try {
    res.json(healthCheck);
  } catch (error) {
    healthCheck.status = 'error';
    res.status(503).json(healthCheck);
  }
});

// Inject io into request context
app.use((req, res, next) => {
  req.io = io;
  next();
});

// ROUTING WITH AUTH LIMITING
app.use('/auth', authLimiter, authRoutes);
app.use('/portfolios', portfolioRoutes);
app.use('/transactions', transactionRoutes);
app.use('/admin', adminRoutes);
app.use('/news', newsRoutes);

// Socket.io connection monitoring
io.on('connection', (socket) => {
  logger.info(`🔌 Connection Established: ${socket.id}`);
  socket.on('disconnect', () => {
    logger.info(`🔌 Connection Closed: ${socket.id}`);
  });
});

// 404 handler
app.use((req, res) => {
  logger.warn(`🔍 404 Attempt: ${req.method} ${req.url}`);
  res.status(404).json({ message: 'Resource not found' });
});

// Global Error Handler (Hides Internal Details)
app.use((err, req, res, next) => {
  logger.error('💥 SERVER ERROR:', err);

  const status = err.status || 500;
  const message = process.env.NODE_ENV === 'production'
    ? 'An internal server error occurred.'
    : err.message;

  res.status(status).json({
    success: false,
    message,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
  });
});

const port = process.env.PORT || 8081;
const serverInstance = server.listen(port, () => {
  logger.info(`🚀 [API SERVER] Listening on port ${port} in ${process.env.NODE_ENV || 'development'} mode`);
});

// CRITICAL PROCESS HANDLERS
process.on('unhandledRejection', (err) => {
  logger.error('❌ FATAL: Unhandled Rejection!', err);
  if (serverInstance) {
    serverInstance.close(() => {
      logger.info('API Server shutting down gracefully...');
      process.exit(1);
    });
  } else {
    process.exit(1);
  }
});

process.on('uncaughtException', (err) => {
  logger.error('❌ FATAL: Uncaught Exception!', err);
  if (serverInstance) {
    serverInstance.close(() => {
      logger.info('API Server shutting down gracefully...');
      process.exit(1);
    });
  } else {
    process.exit(1);
  }
});
