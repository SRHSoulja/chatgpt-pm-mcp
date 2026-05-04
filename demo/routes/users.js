import { Router } from 'express';

const router = Router();

// In-memory users for demo purposes
const users = [
  { id: '1', email: 'alice@example.com', name: 'Alice' },
  { id: '2', email: 'bob@example.com', name: 'Bob' },
];

// GET /users/:id
// TODO: Fix null crash when user not found — returns 500, should return 404 (see TASKS.md — task 2)
router.get('/:id', (req, res) => {
  const user = users.find(u => u.id === req.params.id);
  res.json(user); // crashes with null response if not found
});

export default router;
