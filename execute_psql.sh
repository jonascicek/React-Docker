#!/bin/sh
# execute_psql.sh

# Dieses Skript wird IM Datenbank-Container ausgeführt.
# Es erwartet drei Argumente:
# $1: Datenbankbenutzer
# $2: Datenbankname
# $3: Pfad zur SQL-Datei IM CONTAINER

DB_USER="$1"
DB_NAME="$2"
SQL_FILE="$3"

echo "Container-Skript: Führe psql aus mit Benutzer '$DB_USER', DB '$DB_NAME', Datei '$SQL_FILE'"
/usr/local/bin/psql -U "$DB_USER" -d "$DB_NAME" -f "$SQL_FILE"
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "Container-Skript: psql-Befehl erfolgreich ausgeführt."
else
  echo "Container-Skript: psql-Befehl fehlgeschlagen mit Exit-Code $EXIT_CODE."
fi

exit $EXIT_CODE