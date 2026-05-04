import { Router } from 'express';

const router = Router();

// In-memory users for demo purposes
const users = [
  { id: '1', email: 'alice@example.com', password: 'password123' },
  { id: '2', email: 'bob@example.com', password: 'hunter2' },
];

// POST /auth/login
// TODO: Add rate limiting (see TASKS.md — task 1)
router.post('/login', (req, res) => {
  const { email, password } = req.body;
  const user = users.find(u => u.email === email && u.password === password);
  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  res.json({ ok: true, userId: user.id });
});

export default router;
