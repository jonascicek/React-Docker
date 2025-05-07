import React, { useState } from 'react';

export default function TodoForm({ addTodo }) {
  const [text, setText] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    if (text.trim()) {
      addTodo(text);
      setText('');
    }
  };

  return React.createElement(
    'form',
    { onSubmit: handleSubmit, className: 'flex gap-2 mb-6' },
    React.createElement('input', {
      value: text,
      onChange: (e) => setText(e.target.value),
      placeholder: 'Neue Aufgabe...',
      className:
        'flex-1 px-4 py-2 rounded-md bg-white/20 text-white placeholder-gray-300 focus:outline-none focus:ring-2 focus:ring-emerald-400',
    }),
    React.createElement(
      'button',
      {
        type: 'submit',
        className:
          'bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2 rounded-md font-medium',
      },
      'Hinzufügen'
    )
  );
}
