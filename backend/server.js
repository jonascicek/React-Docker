import express from 'express';
import cors from 'cors';
import * as todosService from './services/todosService.js';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/api/todos', async (req, res) => {
  const todos = await todosService.getTodos();
  res.json(todos);
});

app.get('/api/todos/:id', async (req, res) => {
  const todo = await todosService.getTodoById(req.params.id);
  if (!todo) return res.status(404).json({ error: 'Todo nicht gefunden' });
  res.json(todo);
});

app.post('/api/todos', async (req, res) => {
  const { text } = req.body;
  if (!text) return res.status(400).json({ error: 'Text ist erforderlich' });
  const newTodo = await todosService.createTodo(text);
  res.status(201).json(newTodo);
});

app.delete('/api/todos/:id', async (req, res) => {
  await todosService.deleteTodo(req.params.id);
  res.status(204).send();
});

app.listen(PORT, () => {
  console.log(`Server läuft auf http://localhost:${PORT}`);
});

