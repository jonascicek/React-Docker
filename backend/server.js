const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const logger = require('./config/logger');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({ origin: 'http://localhost:8080' }));
app.use(express.json());

// Logging
logger.info('🚀 Backend-API startet...');
logger.logDatabaseConfig();
logger.info('-------------------------------------------');

// Datenpfade
const DATA_DIR = path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'todos.json');

// Hilfsfunktion: Verzeichnis sicherstellen
const ensureDataDirExists = () => {
  if (!fs.existsSync(DATA_DIR)) {
    try {
      fs.mkdirSync(DATA_DIR, { recursive: true });
      logger.info(`📁 Datenverzeichnis erstellt unter ${DATA_DIR}`);
    } catch (error) {
      logger.error('❌ Fehler beim Erstellen des Datenverzeichnisses:', {
        error: error.message,
        stack: error.stack
      });
    }
  }
};

// Daten aus Datei laden
const readDataFromFile = () => {
  ensureDataDirExists();
  try {
    if (fs.existsSync(DATA_FILE)) {
      const jsonData = fs.readFileSync(DATA_FILE);
      return JSON.parse(jsonData);
    }
  } catch (error) {
    logger.error('❌ Fehler beim Lesen der Daten:', {
      error: error.message,
      stack: error.stack
    });
  }
  logger.info(`📄 Daten nicht gefunden, starte mit leerer Liste.`);
  return { todos: [], nextId: 1 };
};

// Daten in Datei schreiben
const writeDataToFile = (data) => {
  ensureDataDirExists();
  try {
    fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
    logger.debug('✅ Daten erfolgreich gespeichert.');
  } catch (error) {
    logger.error('❌ Fehler beim Schreiben der Daten:', {
      error: error.message,
      stack: error.stack
    });
  }
};

// Initialdaten laden
let { todos, nextId } = readDataFromFile();

// --- API ROUTEN ---

// Begrüßungsseite
app.get('/', (req, res) => {
  res.send('Backend läuft. Verwende /api/todos');
});

// Alle Todos abrufen
app.get('/api/todos', (req, res) => {
  logger.info('GET /api/todos');
  res.json(todos);
});

// Einzelnes Todo nach ID
app.get('/api/todos/:id', (req, res) => {
  const id = parseInt(req.params.id, 10);
  const todo = todos.find((t) => t.id === id);
  if (!todo) {
    logger.warn(`GET /api/todos/${id} - Nicht gefunden`);
    return res.status(404).json({ error: 'Todo nicht gefunden' });
  }
  res.json(todo);
});

// Neues Todo erstellen
app.post('/api/todos', (req, res) => {
  const { text } = req.body;
  if (!text) {
    logger.warn('POST /api/todos - Kein Text gesendet');
    return res.status(400).json({ error: 'Text ist erforderlich' });
  }

  const newTodo = { id: nextId++, text };
  todos.push(newTodo);
  writeDataToFile({ todos, nextId });

  logger.info('POST /api/todos - Neues Todo erstellt', { id: newTodo.id });
  res.status(201).json(newTodo);
});

// Todo löschen
app.delete('/api/todos/:id', (req, res) => {
  const id = parseInt(req.params.id, 10);
  const initialLength = todos.length;
  todos = todos.filter((t) => t.id !== id);

  if (todos.length < initialLength) {
    writeDataToFile({ todos, nextId });
    logger.info(`DELETE /api/todos/${id} - Todo gelöscht`);
    res.status(204).send();
  } else {
    logger.warn(`DELETE /api/todos/${id} - Todo nicht gefunden`);
    res.status(404).json({ error: 'Todo nicht gefunden' });
  }
});

// Server starten
app.listen(PORT, () => {
  logger.info(`🌐 Server läuft auf http://localhost:${PORT}`);
});
