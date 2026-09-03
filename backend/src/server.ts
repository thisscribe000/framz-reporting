import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { initDb } from './db';

import authRoutes from './routes/auth.routes';
import memberRoutes from './routes/members.routes';
import attendanceRoutes from './routes/attendance.routes';
import financialRoutes from './routes/financials.routes';
import analyticsRoutes from './routes/analytics.routes';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
app.use(cors());
app.use(express.json());

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/members', memberRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/financials', financialRoutes);
app.use('/api/analytics', analyticsRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'Framz Reporting API', timestamp: new Date().toISOString() });
});

// Start Server & Init DB
async function main() {
  try {
    await initDb();
    app.listen(PORT, () => {
      console.log(`[Framz Server] Backend API running on port ${PORT}`);
    });
  } catch (err) {
    console.error('[Framz Server Failed to Start]', err);
    process.exit(1);
  }
}

main();
