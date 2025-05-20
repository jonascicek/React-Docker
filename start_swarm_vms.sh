#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "### Start: Swarm VM Setup ###"

VM_NAMES=("manager" "worker1" "worker2" "worker3")
VM_IMAGE="22.04"
UBUNTU_CODENAME="jammy"
VM_CPUS="1"
VM_MEM="2G"
VM_DISK="10G"

# --- 1. Erstelle VMs ---
for vm_name in "${VM_NAMES[@]}"; do
    echo ">>> Erstelle VM: $vm_name (Image: $VM_IMAGE)..."
    if multipass info "$vm_name" >/dev/null 2>&1; then
        echo "VM $vm_name existiert bereits. Überspringe Erstellung."
    else
        multipass launch --name "$vm_name" --cpus "$VM_CPUS" --memory "$VM_MEM" --disk "$VM_DISK" "$VM_IMAGE"
    fi
done

echo ">>> Alle VMs erstellt/überprüft. Warte kurz, bis sie vollständig gebootet sind..."
sleep 15

# --- 2. Installiere Docker auf allen VMs ---
for vm_name in "${VM_NAMES[@]}"; do
    echo ">>> Installiere/Überprüfe Docker auf $vm_name..."
    # Überprüfe, ob Docker bereits installiert ist, um Zeit zu sparen
    if ! multipass exec "$vm_name" -- docker --version >/dev/null 2>&1; then
        echo ">>> Docker wird auf $vm_name installiert..."
        multipass exec "$vm_name" -- sudo apt-get update -y
        multipass exec "$vm_name" -- sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg

        multipass exec "$vm_name" -- sudo install -m 0755 -d /etc/apt/keyrings
        DOCKER_GPG_COMMAND="curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
        multipass exec "$vm_name" -- bash -c "$DOCKER_GPG_COMMAND"
        # Korrigierte Zeile: chmod wird explizit mit bash -c in der VM ausgeführt
        multipass exec "$vm_name" -- bash -c "sudo chmod a+r /etc/apt/keyrings/docker.gpg"

        DOCKER_REPO_COMMAND='echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu '$UBUNTU_CODENAME' stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
        DOCKER_REPO_COMMAND='echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu '$UBUNTU_CODENAME' stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
        multipass exec "$vm_name" -- bash -c "$DOCKER_REPO_COMMAND"

        multipass exec "$vm_name" -- sudo apt-get update -y
        multipass exec "$vm_name" -- sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        multipass exec "$vm_name" -- sudo systemctl start docker
        multipass exec "$vm_name" -- sudo systemctl enable docker
        multipass exec "$vm_name" -- sudo usermod -aG docker ubuntu || echo "Konnte Benutzer ubuntu nicht zur Docker-Gruppe auf $vm_name hinzufügen."
        echo ">>> Docker auf $vm_name installiert."
    else
        echo ">>> Docker ist bereits auf $vm_name installiert."
        # Stelle sicher, dass Docker läuft
        multipass exec "$vm_name" -- sudo systemctl start docker || echo "Konnte Docker-Dienst auf $vm_name nicht starten (läuft vielleicht schon)."
    fi
done
echo ">>> Docker auf allen VMs installiert/überprüft."

# --- 3. Initialisiere Swarm auf dem Manager ---
echo ">>> Initialisiere Docker Swarm auf manager..."
MANAGER_IP=$(multipass info manager --format csv | tail -n1 | cut -d, -f3)
if [ -z "$MANAGER_IP" ]; then
    echo "FEHLER: Manager IP-Adresse konnte nicht abgerufen werden."
    exit 1
fi
echo "Manager IP: $MANAGER_IP"
# Überprüfe den Swarm-Status des Manager-Nodes
MANAGER_SWARM_STATE=$(multipass exec manager -- sudo docker info --format '{{.Swarm.LocalNodeState}}')
MANAGER_IS_CONTROL_PLANE=$(multipass exec manager -- sudo docker info --format '{{.Swarm.ControlAvailable}}')

if [ "$MANAGER_SWARM_STATE" == "active" ] && [ "$MANAGER_IS_CONTROL_PLANE" == "true" ]; then
    echo ">>> Manager ist bereits ein aktiver Swarm Manager."
elif [ "$MANAGER_SWARM_STATE" == "active" ] && [ "$MANAGER_IS_CONTROL_PLANE" != "true" ]; then
    echo ">>> Manager ist Teil eines Swarms, aber nicht als aktiver Manager. Verlasse aktuellen Swarm..."
    multipass exec manager -- sudo docker swarm leave --force
    echo ">>> Initialisiere neuen Swarm auf manager..."
    multipass exec manager -- sudo docker swarm init --advertise-addr "$MANAGER_IP"
else # inactive or pending
    echo ">>> Manager ist nicht Teil eines aktiven Swarms. Initialisiere neuen Swarm..."
    multipass exec manager -- sudo docker swarm init --advertise-addr "$MANAGER_IP"
fi

# --- 4. Hole Worker Join Token ---
echo "Manager IP: $MANAGER_IP"
# Überprüfe, ob der Node bereits Teil eines Swarms ist
if ! multipass exec manager -- sudo docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
    multipass exec manager -- sudo docker swarm init --advertise-addr "$MANAGER_IP"
else
    echo ">>> Manager ist bereits Teil eines Swarms."
    # Stelle sicher, dass es der Manager ist, falls es ein Rejoin war
    if ! multipass exec manager -- sudo docker info --format '{{.Swarm.ControlAvailable}}' | grep -q "true"; then
         echo "WARNUNG: Manager ist Teil eines Swarms, aber nicht als Manager aktiv. Manuelle Überprüfung könnte nötig sein."
    fi
fi


# --- 4. Hole Worker Join Token ---
echo ">>> Hole Swarm Worker Token..."
WORKER_TOKEN=$(multipass exec manager -- sudo docker swarm join-token worker -q)
if [ -z "$WORKER_TOKEN" ]; then
    echo "FEHLER: Worker Join Token konnte nicht abgerufen werden."
    exit 1
fi
echo "Worker Token erhalten."

# --- 5. Joine Worker zum Swarm ---
WORKER_VM_NAMES=("worker1" "worker2" "worker3")
for worker_name in "${WORKER_VM_NAMES[@]}"; do
    echo ">>> Überprüfe/Joine $worker_name zum Swarm..."
    WORKER_SWARM_STATE=$(multipass exec "$worker_name" -- sudo docker info --format '{{.Swarm.LocalNodeState}}')
    if [ "$WORKER_SWARM_STATE" == "active" ]; then
        echo ">>> $worker_name ist bereits Teil eines Swarms. Verlasse aktuellen Swarm..."
        multipass exec "$worker_name" -- sudo docker swarm leave --force
        # Kurze Pause, damit der Leave-Befehl verarbeitet wird
        sleep 2
    fi
    echo ">>> Joine $worker_name zum neuen Swarm..."
    multipass exec "$worker_name" -- sudo docker swarm join --token "$WORKER_TOKEN" "$MANAGER_IP":2377
    echo ">>> $worker_name ist dem Swarm beigetreten."
done

# --- 6. Füge Node Labels hinzu (Wichtig für dein Stack-Deployment) ---
echo ">>> Füge Node Labels hinzu (falls nicht vorhanden)..."
multipass exec manager -- sudo docker node update --label-add role=frontend worker1 || echo "Label für worker1 konnte nicht gesetzt werden (evtl. schon vorhanden)."
multipass exec manager -- sudo docker node update --label-add role=backend worker2 || echo "Label für worker2 konnte nicht gesetzt werden (evtl. schon vorhanden)."
multipass exec manager -- sudo docker node update --label-add role=database worker3 || echo "Label für worker3 konnte nicht gesetzt werden (evtl. schon vorhanden)."
echo ">>> Node Labels überprüft/hinzugefügt."

# --- 7. Deploy Application Stack ---
STACK_FILE_PATH="./stack.yml"
STACK_NAME="myapp"
REMOTE_STACK_FILE_PATH="/tmp/stack.yml"
ENV_FILE_PATH="./.env" # Pfad zur lokalen .env Datei
REMOTE_ENV_FILE_PATH="/tmp/.env" # Zielpfad auf dem Manager
SKIP_TABLE_CREATION="false"

if [ -f "$STACK_FILE_PATH" ]; then
    echo ">>> Übertrage Stack-Datei '$STACK_FILE_PATH' auf Manager als '$REMOTE_STACK_FILE_PATH'..."
    if multipass transfer "$STACK_FILE_PATH" "manager:$REMOTE_STACK_FILE_PATH"; then
        echo ">>> 'multipass transfer' für stack.yml meldet Erfolg."

        echo ">>> Warte 2 Sekunden zur Sicherheit..."
        sleep 2

        echo ">>> Inhalt von /tmp auf dem Manager NACH dem Transfer von stack.yml"
        multipass exec manager -- bash -c "ls -la /tmp"

        echo ">>> Überprüfe Existenz der Stack-Datei '$REMOTE_STACK_FILE_PATH' auf dem Manager..."
        if multipass exec manager -- bash -c "ls -l \"$REMOTE_STACK_FILE_PATH\""; then

            echo ">>> Stack-Datei '$REMOTE_STACK_FILE_PATH' auf Manager gefunden. Deploye Stack '$STACK_NAME'..."
            STACK_DEPLOY_COMMAND="sudo docker stack deploy -c \"$REMOTE_STACK_FILE_PATH\" \"$STACK_NAME\""
            if multipass exec manager -- bash -c "$STACK_DEPLOY_COMMAND"; then
                echo ">>> Stack '$STACK_NAME' erfolgreich deployed/aktualisiert."
            else
                echo "FEHLER: Stack '$STACK_NAME' konnte nicht deployed werden (docker stack deploy fehlgeschlagen)."
                SKIP_TABLE_CREATION="true"
            fi
        else
            echo "FEHLER: Stack-Datei '$REMOTE_STACK_FILE_PATH' konnte auf dem Manager mit 'ls -l' nicht gefunden/angezeigt werden."
            SKIP_TABLE_CREATION="true"
        fi
        
        # Aufräumen
        echo ">>> Entferne temporäre Stack-Datei '$REMOTE_STACK_FILE_PATH' vom Manager (falls vorhanden)..."
        multipass exec manager -- sudo bash -c "rm -f \"$REMOTE_STACK_FILE_PATH\""

    else
        echo "FEHLER: 'multipass transfer' der Stack-Datei '$STACK_FILE_PATH' auf den Manager ist fehlgeschlagen."
        SKIP_TABLE_CREATION="true"
    fi
else
    echo "WARNUNG: Lokale Stack-Datei '$STACK_FILE_PATH' nicht gefunden. Überspringe Stack-Deployment und Tabellenerstellung."
    SKIP_TABLE_CREATION="true"
fi

# --- 8. Initialisiere Datenbank Tabelle (Beispiel) ---
if [ "$SKIP_TABLE_CREATION" != "true" ]; then
    echo ">>> Versuche, Schema aus SQL-Datei in der Datenbank zu initialisieren..."
    DB_SERVICE_NAME="myapp_database"
    DB_NODE="worker3"
    DB_USER="todoapp"
    DB_NAME="todos"
    
    LOCAL_SQL_FILE_PATH="./backend/sql/initial_schema.sql" 
    REMOTE_SQL_FILE_ON_NODE="/tmp/initial_schema.sql"    
    SQL_FILE_IN_CONTAINER="/tmp/initial_schema.sql"      

    # Pfade für das neue execute_psql.sh Skript
    LOCAL_EXEC_SCRIPT_PATH="./execute_psql.sh" # ANPASSEN, falls du es woanders speicherst
    REMOTE_EXEC_SCRIPT_ON_NODE="/tmp/execute_psql.sh"
    EXEC_SCRIPT_IN_CONTAINER="/tmp/execute_psql.sh"

    if [ ! -f "$LOCAL_SQL_FILE_PATH" ]; then
        echo "FEHLER: Lokale SQL-Datei '$LOCAL_SQL_FILE_PATH' nicht gefunden."
        SKIP_TABLE_CREATION="true" 
    fi
    if [ ! -f "$LOCAL_EXEC_SCRIPT_PATH" ]; then
        echo "FEHLER: Lokales psql-Ausführungsskript '$LOCAL_EXEC_SCRIPT_PATH' nicht gefunden."
        SKIP_TABLE_CREATION="true"
    fi
fi

if [ "$SKIP_TABLE_CREATION" != "true" ]; then 
    echo ">>> Warte maximal 2 Minuten darauf, dass der Dienst $DB_SERVICE_NAME auf $DB_NODE einen laufenden Container hat..."
    DB_CONTAINER_ID=""
    # ... (Container-Suchschleife bleibt gleich) ...
    for i in {1..24}; do
        DB_CONTAINER_ID=$(multipass exec "$DB_NODE" -- sudo docker ps --filter "label=com.docker.swarm.service.name=${DB_SERVICE_NAME}" --format "{{.ID}}" | head -n 1)
        if [ -n "$DB_CONTAINER_ID" ]; then
            echo ">>> Datenbank-Container $DB_CONTAINER_ID auf $DB_NODE gefunden."
            echo ">>> Warte 10 Sekunden, damit der DB-Server im Container initialisiert werden kann..."
            sleep 10
            break
        fi
        echo ">>> Datenbank-Container für $DB_SERVICE_NAME auf $DB_NODE noch nicht gefunden. Warte 5 Sekunden... (Versuch $i/24)"
        sleep 5
    done

    if [ -z "$DB_CONTAINER_ID" ]; then
        echo "FEHLER: Konnte nach 2 Minuten keinen laufenden Container für den Dienst $DB_SERVICE_NAME auf $DB_NODE finden."
        echo ">>> Überspringe Schema-Initialisierung."
    else
        # Schritt 2a: SQL-Datei auf Node übertragen
        echo ">>> Übertrage SQL-Datei '$LOCAL_SQL_FILE_PATH' auf '$DB_NODE:$REMOTE_SQL_FILE_ON_NODE'..."
        if multipass transfer "$LOCAL_SQL_FILE_PATH" "$DB_NODE:$REMOTE_SQL_FILE_ON_NODE"; then
            echo ">>> SQL-Datei erfolgreich auf $DB_NODE übertragen."

            # Schritt 2b: execute_psql.sh Skript auf Node übertragen
            echo ">>> Übertrage psql-Ausführungsskript '$LOCAL_EXEC_SCRIPT_PATH' auf '$DB_NODE:$REMOTE_EXEC_SCRIPT_ON_NODE'..."
            if multipass transfer "$LOCAL_EXEC_SCRIPT_PATH" "$DB_NODE:$REMOTE_EXEC_SCRIPT_ON_NODE"; then
                echo ">>> psql-Ausführungsskript erfolgreich auf $DB_NODE übertragen."

                # Schritt 3a: SQL-Datei in Container streamen/kopieren
                echo ">>> Versuche, SQL-Datei von '$DB_NODE:$REMOTE_SQL_FILE_ON_NODE' in den Container '$DB_CONTAINER_ID' als '$SQL_FILE_IN_CONTAINER' zu streamen..."
                STREAM_COMMAND="cat '$REMOTE_SQL_FILE_ON_NODE' | sudo docker exec -i '$DB_CONTAINER_ID' sh -c 'cat > \"$SQL_FILE_IN_CONTAINER\"'"
                echo "DEBUG: STREAM_COMMAND auf $DB_NODE wird sein: $STREAM_COMMAND"
                if multipass exec "$DB_NODE" -- bash -c "$STREAM_COMMAND"; then
                    echo ">>> SQL-Datei erfolgreich in den Container $DB_CONTAINER_ID gestreamt."

                    # --- DEBUG-SCHRITTE für die SQL-Datei im Container (optional, aber gut für die Fehlersuche) ---
                    echo ">>> DEBUG: Überprüfe Existenz von $SQL_FILE_IN_CONTAINER im Container $DB_CONTAINER_ID..."
                    multipass exec "$DB_NODE" -- sudo docker exec "$DB_CONTAINER_ID" sh -c "ls -l '$SQL_FILE_IN_CONTAINER'" || echo "DEBUG: ls für SQL-Datei fehlgeschlagen"
                    # --- ENDE DEBUG-SCHRITTE ---

                    # Schritt 3b: execute_psql.sh Skript in Container kopieren
                    # Verwende docker cp, das ist oft robuster für ganze Dateien als cat-Pipes
                    # docker cp benötigt den Pfad auf dem Host (Node) und den Pfad im Container
                    # Syntax: sudo docker cp /pfad/auf/node container_id:/pfad/im/container
                    COPY_EXEC_SCRIPT_TO_CONTAINER_COMMAND="sudo docker cp '$REMOTE_EXEC_SCRIPT_ON_NODE' '$DB_CONTAINER_ID:$EXEC_SCRIPT_IN_CONTAINER'"
                    echo "DEBUG: COPY_EXEC_SCRIPT_TO_CONTAINER_COMMAND auf $DB_NODE wird sein: $COPY_EXEC_SCRIPT_TO_CONTAINER_COMMAND"
                    if multipass exec "$DB_NODE" -- bash -c "$COPY_EXEC_SCRIPT_TO_CONTAINER_COMMAND"; then
                        echo ">>> psql-Ausführungsskript erfolgreich in den Container $DB_CONTAINER_ID kopiert."

                        # Schritt 4: Skript im Container ausführbar machen
                        CHMOD_EXEC_SCRIPT_COMMAND="sudo docker exec '$DB_CONTAINER_ID' chmod +x '$EXEC_SCRIPT_IN_CONTAINER'"
                        echo "DEBUG: CHMOD_EXEC_SCRIPT_COMMAND auf $DB_NODE wird sein: $CHMOD_EXEC_SCRIPT_COMMAND"
                        if multipass exec "$DB_NODE" -- bash -c "$CHMOD_EXEC_SCRIPT_COMMAND"; then
                            echo ">>> psql-Ausführungsskript im Container ausführbar gemacht."

                            # Schritt 5: Skript im Container ausführen
                            echo ">>> Versuche Schema über '$EXEC_SCRIPT_IN_CONTAINER' im Container $DB_CONTAINER_ID zu erstellen..."
                            # Die Argumente müssen für die Shell im Container korrekt gequotet sein, falls sie Leerzeichen etc. enthalten.
                            # Hier sind sie einfach, aber gute Praxis:
                            RUN_EXEC_SCRIPT_COMMAND="sudo docker exec '$DB_CONTAINER_ID' '$EXEC_SCRIPT_IN_CONTAINER' '$DB_USER' '$DB_NAME' '$SQL_FILE_IN_CONTAINER'"
                            echo "DEBUG: RUN_EXEC_SCRIPT_COMMAND auf $DB_NODE wird sein: $RUN_EXEC_SCRIPT_COMMAND"
                            if multipass exec "$DB_NODE" -- bash -c "$RUN_EXEC_SCRIPT_COMMAND"; then
                                echo ">>> Schema aus '$SQL_FILE_IN_CONTAINER' erfolgreich initialisiert via externem Skript."
                            else
                                LAST_EXIT_CODE=$?
                                echo "FEHLER: Schema-Initialisierung via externem Skript '$EXEC_SCRIPT_IN_CONTAINER' fehlgeschlagen."
                                echo "DEBUG: Exit-Code des externen Skripts (multipass/docker exec): $LAST_EXIT_CODE"
                            fi
                        else
                            echo "FEHLER: Konnte psql-Ausführungsskript im Container nicht ausführbar machen."
                        fi
                        # Schritt 6b: Temporäres execute_psql.sh Skript im Container löschen
                        echo ">>> Entferne temporäres psql-Ausführungsskript '$EXEC_SCRIPT_IN_CONTAINER' aus dem Container..."
                        multipass exec "$DB_NODE" -- sudo docker exec "$DB_CONTAINER_ID" rm -f "$EXEC_SCRIPT_IN_CONTAINER" || echo "WARNUNG: Konnte psql-Ausführungsskript im Container nicht entfernen."
                    else
                        echo "FEHLER: Konnte psql-Ausführungsskript nicht von $DB_NODE in den Container $DB_CONTAINER_ID kopieren."
                    fi
                    # Schritt 6a: Temporäre SQL-Datei im Container löschen
                    echo ">>> Entferne temporäre SQL-Datei '$SQL_FILE_IN_CONTAINER' aus dem Container..."
                    multipass exec "$DB_NODE" -- sudo docker exec "$DB_CONTAINER_ID" rm -f "$SQL_FILE_IN_CONTAINER" || echo "WARNUNG: Konnte SQL-Datei im Container nicht entfernen."
                else
                    echo "FEHLER: Konnte SQL-Datei nicht von $DB_NODE in den Container $DB_CONTAINER_ID streamen."
                fi
                # Schritt 6c: Temporäres execute_psql.sh Skript auf dem Node löschen
                echo ">>> Entferne temporäres psql-Ausführungsskript '$REMOTE_EXEC_SCRIPT_ON_NODE' von $DB_NODE..."
                multipass exec "$DB_NODE" -- sudo rm -f "$REMOTE_EXEC_SCRIPT_ON_NODE" || echo "WARNUNG: Konnte psql-Ausführungsskript auf $DB_NODE nicht entfernen."
            else
                echo "FEHLER: 'multipass transfer' des psql-Ausführungsskripts '$LOCAL_EXEC_SCRIPT_PATH' auf den Node '$DB_NODE' ist fehlgeschlagen."
            fi
            # Schritt 6d: Temporäre SQL-Datei auf dem Node löschen
            echo ">>> Entferne temporäre SQL-Datei '$REMOTE_SQL_FILE_ON_NODE' von $DB_NODE..."
            multipass exec "$DB_NODE" -- sudo rm -f "$REMOTE_SQL_FILE_ON_NODE" || echo "WARNUNG: Konnte SQL-Datei auf $DB_NODE nicht entfernen."
        else 
            echo "FEHLER: 'multipass transfer' der SQL-Datei '$LOCAL_SQL_FILE_PATH' auf den Node '$DB_NODE' ist fehlgeschlagen."
        fi
    fi
fi
echo ">>> Docker Swarm Setup und Initialisierung abgeschlossen."
echo ">>> Finaler VM Status:"
multipass list
echo ">>> Swarm Nodes:"
multipass exec manager -- sudo docker node ls
echo ">>> Aktueller Stack Status (falls deployed):"
if [ "$SKIP_TABLE_CREATION" != "true" ]; then # Zeigt den Stack nur an, wenn ein Deployment versucht wurde
    multipass exec manager -- sudo docker stack ps "$STACK_NAME"
fi

echo "### Ende: Swarm VM Setup ###"