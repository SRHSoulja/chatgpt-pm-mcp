import { Router } from 'express';

const router = Router();

// In-memory users for demo purposes
const users = [
  { id: '1', email: 'alice@example.com', name: 'Alice' },
  { id: '2', email: 'bob@example.com', name: 'Bob' },
];

// GET /users/:id
// TODO: Fix crash when user not found — should return 404 JSON (see TASKS.md — task 2)
router.get('/:id', (req, res) => {
  const user = users.find(u => u.id === req.params.id);
  res.json({ id: user.id, email: user.email, name: user.name }); // crashes (TypeError) when user is undefined
});

export default router;
