const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({ origin: 'http://localhost:8080' }));
app.use(express.json());

// Neuer Pfad: /app/data/todos.json
const DATA_DIR = path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'todos.json');

// Sicherstellen, dass das Verzeichnis existiert
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR);
}

// Todos laden
const loadTodos = () => {
  if (!fs.existsSync(DATA_FILE)) {
    return [];
  }
  const data = fs.readFileSync(DATA_FILE, 'utf-8');
  return JSON.parse(data);
};

// Todos speichern
const saveTodos = (todos) => {
  try {
    console.log('Speichere Todos in Datei:', JSON.stringify(todos, null, 2));
    fs.writeFileSync(DATA_FILE, JSON.stringify(todos, null, 2));
    console.log('Todos erfolgreich gespeichert.');
  } catch (err) {
    console.error('Fehler beim Speichern der Todos:', err);
  }
};

let todos = loadTodos();
console.log('Initiale Todos:', todos);

app.get('/', (req, res) => {
  res.send('Backend läuft! Verwende /api/todos für die API.');
});

app.get('/api/todos', (req, res) => {
  res.json(todos);
});

app.get('/api/todos/:id', (req, res) => {
  const todo = todos.find((t) => t.id === parseInt(req.params.id));
  if (!todo) return res.status(404).send('Todo nicht gefunden');
  res.json(todo);
});

app.post('/api/todos', (req, res) => {
  console.log('POST-Anfrage empfangen:', req.body);
  const newTodo = { id: Date.now(), text: req.body.text };
  todos.push(newTodo);
  console.log('Neues Todo hinzugefügt:', newTodo);
  saveTodos(todos);
  res.status(201).json(newTodo);
});

app.delete('/api/todos/:id', (req, res) => {
  const id = parseInt(req.params.id);
  todos = todos.filter((t) => t.id !== id);
  console.log('Lösche Todo mit ID:', id);
  saveTodos(todos);
  res.status(204).send();
});

app.listen(PORT, () => {
  console.log(`Backend läuft auf http://localhost:${PORT}`);
});
