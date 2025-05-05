import React from 'react';

export default function TodoList({ todos, deleteTodo }) {
  return React.createElement(
    'ul',
    null,
    todos.map((todo) =>
      React.createElement(
        'li',
        { key: todo.id },
        todo.text,
        React.createElement(
          'button',
          { onClick: () => deleteTodo(todo.id) },
          'Löschen'
        )
      )
    )
  );
}
