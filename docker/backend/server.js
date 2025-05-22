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

app.get('/api/health', async (req, res) => {
  try {
    // Testabfrage an die Datenbank (z. B. COUNT oder ping)
    await todosService.getTodos(); // Minimaler Check, ob DB antwortet
    res.status(200).json({ status: 'ok' });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});


app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server läuft auf http://0.0.0.0:${PORT}`);
});

