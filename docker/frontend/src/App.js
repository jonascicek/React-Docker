import React, { useState, useEffect } from 'react';
import TodoForm from './TodoForm.js';
import TodoList from './TodoList.js';

const API_URL = import.meta.env.VITE_API_URL || '/api';

export default function App() {
  const [todos, setTodos] = useState([]);

  useEffect(() => {
    fetch(`${API_URL}/todos`)
      .then((res) => res.json())
      .then((data) => setTodos(data))
      .catch((err) => console.error('Fehler beim Laden der Todos:', err));
  }, []);

  const addTodo = (text) => {
    fetch(`${API_URL}/todos`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text }),
    })
      .then((res) => res.json())
      .then((data) => setTodos((prev) => [...prev, data]))
      .catch((err) => console.error('Fehler beim Hinzufügen des Todos:', err));
  };

  const deleteTodo = (id) => {
    fetch(`${API_URL}/todos/${id}`, { method: 'DELETE' })
      .then((res) => {
        if (res.ok) {
          setTodos((prev) => prev.filter((todo) => todo.id !== id));
        }
      })
      .catch((err) => console.error('Fehler beim Löschen:', err));
  };

  return React.createElement(
    'div',
    {
      className:
        'min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center px-4',
    },
    React.createElement(
      'div',
      {
        className:
          'bg-white/10 backdrop-blur-md shadow-xl p-8 rounded-2xl w-full max-w-md text-white',
      },
      React.createElement(
        'h1',
        { className: 'text-3xl font-bold text-center mb-6' },
        '📝 Meine Notizen'
      ),
      React.createElement(TodoForm, { addTodo }),
      React.createElement(TodoList, { todos, deleteTodo })
    )
  );
}
