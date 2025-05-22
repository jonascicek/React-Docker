import React from 'react';

export default function TodoList({ todos, deleteTodo }) {
  return React.createElement(
    'ul',
    { className: 'space-y-2' },
    todos.map((todo) =>
      React.createElement(
        'li',
        {
          key: todo.id,
          className:
            'bg-white/10 px-4 py-2 rounded-md flex justify-between items-center shadow',
        },
        React.createElement('span', null, todo.text),
        React.createElement(
          'button',
          {
            onClick: () => deleteTodo(todo.id),
            className:
              'text-sm text-red-400 hover:text-red-600 font-medium',
          },
          'Löschen'
        )
      )
    )
  );
}
