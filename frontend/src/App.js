import React, { useState, useEffect } from 'react';
import TodoForm from './TodoForm.js';
import TodoList from './TodoList.js';

const API_URL = import.meta.env.VITE_API_URL;

export default function App() {
  const [todos, setTodos] = useState([]);

  useEffect(() => {
    fetch(`${API_URL}/api/todos`)
      .then((res) => res.json())
      .then((data) => setTodos(data))
      .catch((err) => console.error('Fehler beim Laden der Todos:', err));
  }, []);

  const addTodo = (text) => {
    fetch(`${API_URL}/api/todos`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ text }),
    })
      .then((res) => res.json())
      .then((data) => {
        console.log('Todo hinzugefügt:', data);
        setTodos([...todos, data]);
      })
      .catch((err) => console.error('Fehler beim Hinzufügen des Todos:', err));
  };

  const deleteTodo = (id) => {
    setTodos(todos.filter(todo => todo.id !== id));
  };

  return React.createElement(
    'div',
    { style: { padding: '2rem' } },
    React.createElement('h1', null, 'Meine To-do-Liste'),
    React.createElement(TodoForm, { addTodo }),
    React.createElement(TodoList, { todos, deleteTodo })
  );
}
