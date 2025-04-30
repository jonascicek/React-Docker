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
    { onSubmit: handleSubmit },
    React.createElement('input', {
      value: text,
      onChange: (e) => setText(e.target.value),
      placeholder: 'Neue Aufgabe'
    }),
    React.createElement('button', { type: 'submit' }, 'Hinzufügen')
  );
}
