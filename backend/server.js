const express = require('express');
const cors = require('cors'); // Importiere cors
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({ origin: 'http://localhost:8080' })); // Aktiviere cors mit spezifischer Origin
app.use(express.json());

const DATA_FILE = path.join(__dirname, 'todos.json');

// Hilfsfunktion: Todos aus Datei laden
const loadTodos = () => {
  if (!fs.existsSync(DATA_FILE)) {
    return [];
  }
  const data = fs.readFileSync(DATA_FILE, 'utf-8');
  return JSON.parse(data);
};

// Hilfsfunktion: Todos in Datei speichern
const saveTodos = (todos) => {
  try {
    console.log('Speichere Todos in Datei:', JSON.stringify(todos, null, 2)); // Debugging-Log
    fs.writeFileSync(DATA_FILE, JSON.stringify(todos, null, 2));
    console.log('Todos erfolgreich gespeichert.');
  } catch (err) {
    console.error('Fehler beim Speichern der Todos:', err);
  }
};

let todos = loadTodos();
console.log('Initiale Todos:', todos); // Debugging-Log

// Root-Route
app.get('/', (req, res) => {
  res.send('Backend läuft! Verwende /api/todos für die API.');
});

// Alle Todos abrufen
app.get('/api/todos', (req, res) => {
  res.json(todos);
});

// Einzelnes Todo abrufen
app.get('/api/todos/:id', (req, res) => {
  const todo = todos.find((t) => t.id === parseInt(req.params.id));
  if (!todo) return res.status(404).send('Todo nicht gefunden');
  res.json(todo);
});

// Neues Todo hinzufügen
app.post('/api/todos', (req, res) => {
  console.log('POST-Anfrage empfangen:', req.body); // Debugging-Log
  const newTodo = { id: Date.now(), text: req.body.text };
  todos.push(newTodo);
  console.log('Neues Todo hinzugefügt:', newTodo); // Debugging-Log
  saveTodos(todos); // Todos speichern
  res.status(201).json(newTodo);
});

// Todo löschen
app.delete('/api/todos/:id', (req, res) => {
  todos = todos.filter((t) => t.id !== parseInt(req.params.id));
  saveTodos(todos); // Todos speichern
  res.status(204).send();
});

app.listen(PORT, () => {
  console.log(`Backend läuft auf http://localhost:${PORT}`);
});