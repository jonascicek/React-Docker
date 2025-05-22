## Entscheidung für den Volume-Typ: Bind Mount

Ich habe mich in dieser Aufgabe für einen **Bind Mount** entschieden, um die Datei `todos.json`, in der die Backend-Daten gespeichert werden, direkt mit dem Hostsystem zu verbinden.

### Warum Bind Mount?

Der Hauptgrund war, dass ich während der Entwicklung möglichst flexibel und transparent arbeiten wollte. Mit einem Bind Mount kann ich jederzeit die JSON-Datei auf meinem Rechner öffnen, den Inhalt kontrollieren oder sogar manuell anpassen. Das hat mir vor allem beim Testen der Persistenz sehr geholfen, weil ich direkt sehen konnte, ob und wann sich etwas gespeichert hat.

Ein weiterer Vorteil ist, dass ich nichts zusätzlich konfigurieren muss. Die Datei liegt sowieso in meinem Projektordner – und durch das `-v` Flag kann ich sie ganz einfach in den Container mounten, ohne vorher ein Volume benennen oder verwalten zu müssen.

### Vorteile des Bind Mounts:
- Ich sehe die Daten direkt auf dem Host.
- Änderungen an der Datei sind sofort nachvollziehbar.
- Keine zusätzliche Konfiguration oder Volume-Verwaltung nötig.
- Ideal für schnelles Debugging und lokale Tests.

### Nachteile gegenüber einem benannten Volume:
- Pfadangaben sind vom Betriebssystem abhängig (z. B. Windows vs. Linux).
- In produktiven Umgebungen kann es unübersichtlich oder fehleranfällig sein.
- Es besteht ein höheres Risiko, versehentlich am Live-Datensatz auf dem Host Änderungen vorzunehmen.

### Fazit:

Gerade für eine lokale Entwicklungsumgebung war der Bind Mount für mich die beste Wahl. Ich konnte damit einfacher kontrollieren, ob meine Persistenzlogik funktioniert, und musste mich nicht zusätzlich mit Volume-Management beschäftigen. In einer Produktionsumgebung würde ich wahrscheinlich eher auf ein benanntes Volume wechseln, um eine saubere Trennung zum Hostsystem zu haben.
