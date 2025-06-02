import pool from '../config/db.js';

export async function getTodos() {
    const result = await pool.query('SELECT * FROM todos ORDER BY id');
    return result.rows;
}

export async function getTodoById(id) {
    const result = await pool.query('SELECT * FROM todos WHERE id = $1', [id]);
    return result.rows[0];
}

export async function createTodo(text) {
    const result = await pool.query(
        'INSERT INTO todos (text) VALUES ($1) RETURNING *',
        [text]
    );
    return result.rows[0];
}

export async function deleteTodo(id) {
    await pool.query('DELETE FROM todos WHERE id = $1', [id]);
}