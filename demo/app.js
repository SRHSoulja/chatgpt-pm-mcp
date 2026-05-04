import express from 'express';
import authRoutes from './routes/auth.js';
import userRoutes from './routes/users.js';

const app = express();
app.use(express.json());

app.use('/auth', authRoutes);
app.use('/users', userRoutes);

app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'Demo API running' });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`Demo API running on http://localhost:${PORT}`);
});
