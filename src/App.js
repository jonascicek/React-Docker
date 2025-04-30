import React, { useState } from 'react';
import TodoForm from './TodoForm.js';
import TodoList from './TodoList.js';

export default function App() {
  const [todos, setTodos] = useState([]);

  const addTodo = (text) => {
    setTodos([...todos, { id: Date.now(), text }]);
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
