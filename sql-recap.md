# SQL-Recap – Datenmodell & CRUD-Abfragen (Users + Todos)

## Datenmodell

### Tabelle: `users`

| Spaltenname | Datentyp     | Beschreibung                  | Schlüssel       |
|-------------|--------------|-------------------------------|-----------------|
| id          | INTEGER      | Eindeutige Nutzer-ID          | PRIMARY KEY     |
| username    | VARCHAR(50)  | Nutzername (eindeutig)        |                 |
| email       | VARCHAR(100) | E-Mail-Adresse des Nutzers    |                 |

---

### Tabelle: `todos`

| Spaltenname | Datentyp     | Beschreibung                        | Schlüssel        |
|-------------|--------------|-------------------------------------|------------------|
| id          | INTEGER      | Eindeutige ID des Todos             | PRIMARY KEY      |
| user_id     | INTEGER      | Verknüpfung zum Nutzer              | FOREIGN KEY (FK) |
| text        | VARCHAR(255) | Beschreibung der Aufgabe            |                  |
| is_done     | BOOLEAN      | Gibt an, ob die Aufgabe erledigt ist|                  |
| created_at  | TIMESTAMP    | Zeitpunkt der Erstellung            |                  |

### Beziehung:
Ein Todo gehört genau **einem** User (`user_id` verweist auf `users.id`).

---

## SQL-Befehle (CRUD)

### CREATE

#### Nutzer anlegen

```sql
INSERT INTO users (username, email)
VALUES ('jonas', 'jonas@example.com');
```
#### Todo anlegen

```sql
INSERT INTO todos (user_id, text, is_done, created_at)
VALUES (1, 'Notizen-Feature fertig machen', FALSE, CURRENT_TIMESTAMP);
```
### READ

#### Alle Todos abrufen

```sql
SELECT * FROM todos;
```

#### Todos eines bestimmten Nutzers abrufen

```sql
SELECT * FROM todos WHERE user_id = 1;
```

#### Einzelnes Todo nach ID

```sql
SELECT * FROM todos WHERE id = 5;
```

#### Nur erledigte Todos

```sql
SELECT * FROM todos WHERE is_done = TRUE;
```

#### Nutzer mit ihren Todos

```sql
SELECT u.username, t.text, t.is_done
FROM users u
JOIN todos t ON u.id = t.user_id;
```

### UPDATE

#### Text eines Todos ändern

```sql
UPDATE todos SET text = 'Aufgabe überarbeiten' WHERE id = 5;
```

#### Todo als erledigt markieren

```sql
UPDATE todos SET is_done = TRUE WHERE id = 5;
```

### DELETE

#### Todo löschen

```sql
DELETE FROM todos WHERE id = 5;
```

#### Alle Todos eines Users löschen

```sql
DELETE FROM todos WHERE user_id = 1;
```
