# Kubernetes-Konfiguration für die Mini-Notizblock-Anwendung

Dieses Verzeichnis enthält die Kubernetes-Manifeste für das Deployment der Mini-Notizblock-Anwendung, bestehend aus einem Frontend, einem Backend und einer PostgreSQL-Datenbank.

## Voraussetzungen

- Ein laufender Kubernetes-Cluster (z.B. Docker Desktop, Minikube, GKE, AKS, EKS).
- `kubectl` CLI konfiguriert für den Zugriff auf deinen Cluster.
- Die Docker-Images für Frontend (`jiggly/frontend-image:latest`) und Backend (`jiggly/backend-image:latest`) müssen in einer Registry verfügbar sein, auf die dein Cluster zugreifen kann (oder lokal im Cluster, falls z.B. Docker Desktop verwendet wird).
- Ein Ingress Controller (wie Nginx Ingress Controller) muss im Cluster installiert sein, wenn Ingress verwendet werden soll.
- Optional: Für das Monitoring ein installierter Kubernetes Metrics Server und ein Monitoring-Stack wie `kube-prometheus-stack`.

## Verzeichnisstruktur

```
k8s/
├── backend/
│   ├── deployment.yaml
│   └── service.yaml
├── database/
│   ├── configmap.yaml      # Enthält das initial_schema.sql
│   ├── deployment.yaml
│   ├── pvc.yaml            # PersistentVolumeClaim für die Datenbank (optional, aber empfohlen)
│   ├── secret.yaml         # Enthält die Datenbank-Credentials
│   └── service.yaml
├── frontend/
│   ├── deployment.yaml
│   └── service.yaml
├── ingress.yaml            # Ingress-Ressource für den externen Zugriff
└── README.md               # Diese Datei
```

## Komponenten

Alle Komponenten werden im Namespace `myapp` deployed.

### 1. Namespace

Ein Namespace `myapp` wird verwendet, um die Ressourcen dieser Anwendung zu isolieren.
Erstellung (falls noch nicht geschehen):

```bash
kubectl create namespace myapp
```

### 2. Datenbank (PostgreSQL)

- **ConfigMap (`database/configmap.yaml`)**:
  - Name: `db-schema`
  - Enthält das SQL-Skript `initial_schema.sql` zur Erstellung der `notes`-Tabelle. Dieses Skript wird beim ersten Start des Datenbankcontainers ausgeführt, wenn das Datenverzeichnis leer ist.
- **Secret (`database/secret.yaml`)**:
  - Name: `db-credentials`
  - Enthält das `POSTGRES_PASSWORD` für den Datenbankbenutzer. Es wird empfohlen, die Werte in dieser Datei (Base64-kodiert) vor dem Anwenden anzupassen oder die Datei als Vorlage zu verwenden und das Secret manuell mit `kubectl create secret generic` zu erstellen.
- **PersistentVolumeClaim (`database/pvc.yaml`) (Empfohlen für Datenpersistenz)**:
  - Name: `db-pvc`
  - Fordert persistenten Speicher für die Datenbank an (z.B. 1Gi).
  - Die tatsächliche Bereitstellung des Speichers hängt von der Konfiguration deines Kubernetes-Clusters und der verfügbaren `StorageClass` ab.
  - Wenn ein PVC verwendet wird, sollte das `emptyDir`-Volume im `database/deployment.yaml` durch dieses PVC ersetzt werden.
- **Deployment (`database/deployment.yaml`)**:
  - Name: `database`
  - Verwendet das Image `postgres:17-alpine`.
  - Definiert Umgebungsvariablen:
    - `POSTGRES_USER`: `meinnotizblockuser`
    - `POSTGRES_PASSWORD`: Wird aus dem Secret `db-credentials` bezogen.
    - `POSTGRES_DB`: `notizblock_prod_db` (diese Datenbank wird automatisch erstellt).
  - **Datenpersistenz:**
    - **Option 1 (Nicht-Persistent):** Verwendet ein `emptyDir`-Volume für `/var/lib/postgresql/data`. **Achtung:** Daten gehen verloren, wenn der Pod neu gestartet wird. Ein benutzerdefiniertes `command` und `args` kann verwendet werden, um `initdb` bei jedem Start mit `emptyDir` zu erzwingen.
    - **Option 2 (Persistent - Empfohlen):** Verwendet ein Volume, das durch den `db-pvc` (PersistentVolumeClaim) bereitgestellt wird, gemountet unter `/var/lib/postgresql/data`. In diesem Fall wird das `initial_schema.sql` nur beim allerersten Start ausgeführt, wenn das Volume leer ist. Das benutzerdefinierte `command` zum Leeren des Verzeichnisses sollte entfernt werden.
  - Mountet die `db-schema`-ConfigMap nach `/docker-entrypoint-initdb.d/`, damit das `initial_schema.sql`-Skript automatisch ausgeführt wird (wenn das Datenverzeichnis initial leer ist).
  - Definiert Readiness- und Liveness-Probes.
- **Service (`database/service.yaml`)**:
  - Name: `database`
  - Typ: `ClusterIP` (Standard)
  - Macht den PostgreSQL-Server auf Port `5432` für andere Pods im Cluster (innerhalb des `myapp`-Namespace unter dem DNS-Namen `database`) verfügbar.

### 3. Backend (Node.js API)

- **Deployment (`backend/deployment.yaml`)**:
  - Name: `backend`
  - Verwendet das Image `mephisto1339/backend-image:latest`.
  - Definiert Umgebungsvariablen für die Datenbankverbindung:
    - `DB_HOST`: `database` (verweist auf den Datenbank-Service)
    - `DB_PORT`: `5432`
    - `DB_USER`: `meinnotizblockuser`
    - `DB_NAME`: `notizblock_prod_db`
    - `DB_PASSWORD`: Wird aus dem Secret `db-credentials` bezogen.
  - Lauscht auf Port `3000`.
- **Service (`backend/service.yaml`)**:
  - Name: `backend` (oder `backend-service`, stelle Konsistenz sicher)
  - Typ: `ClusterIP` (Standard)
  - Macht die Backend-API auf Port `3000` für andere Pods im Cluster verfügbar.

### 4. Frontend (React/Static)

- **Deployment (`frontend/deployment.yaml`)**:
  - Name: `frontend`
  - Verwendet das Image `mephisto1339/frontend-image:latest`.
  - Der Container (vermutlich Nginx oder ein ähnlicher Webserver) lauscht auf Port `80`.
- **Service (`frontend/service.yaml`)**:
  - Name: `frontend` (oder `frontend-service`, stelle Konsistenz sicher)
  - Typ: `ClusterIP` (Standard, wenn Ingress verwendet wird). Kann auch `LoadBalancer` oder `NodePort` sein für direkten externen Zugriff ohne Ingress.
  - Macht das Frontend auf Port `80` intern im Cluster verfügbar.

### 5. Ingress (`ingress.yaml`)

- **Ingress (`ingress.yaml`)**:
  - Name: `myapp-ingress`
  - Definiert Regeln für den externen Zugriff auf die Anwendung über HTTP/HTTPS.
  - Erfordert einen installierten Ingress Controller im Cluster (z.B. Nginx Ingress Controller).
  - `ingressClassName`: Gibt den zu verwendenden Ingress Controller an (z.B. `nginx`).
  - **Host-basierte Regeln:**
    - Definiert einen Hostnamen (z.B. `myapp.local` für lokale Entwicklung, oder eine öffentliche Domain).
  - **Pfad-basierte Regeln:**
    - Leitet Anfragen an `http://<host>/api/*` an den `backend`-Service auf Port `3000` weiter.
    - Leitet Anfragen an `http://<host>/*` (alle anderen Pfade) an den `frontend`-Service auf Port `80` weiter.
  - Kann Annotationen für spezifisches Verhalten enthalten (z.B. `rewrite-target`, SSL-Konfiguration).

## Deployment-Reihenfolge

Es wird empfohlen, die Ressourcen in der folgenden Reihenfolge anzuwenden, um Abhängigkeiten korrekt aufzulösen:

1.  **Namespace (falls noch nicht erstellt):**
    ```bash
    kubectl create namespace myapp
    ```
2.  **Datenbank-Ressourcen:**
    ```bash
    kubectl apply -f k8s/database/secret.yaml -n myapp
    kubectl apply -f k8s/database/configmap.yaml -n myapp
    # Optional, aber empfohlen für Persistenz:
    kubectl apply -f k8s/database/pvc.yaml -n myapp
    kubectl apply -f k8s/database/deployment.yaml -n myapp # Stelle sicher, dass dies das PVC verwendet, falls erstellt
    kubectl apply -f k8s/database/service.yaml -n myapp
    ```
3.  **Backend-Ressourcen:**
    ```bash
    kubectl apply -f k8s/backend/deployment.yaml -n myapp
    kubectl apply -f k8s/backend/service.yaml -n myapp
    ```
4.  **Frontend-Ressourcen:**
    ```bash
    kubectl apply -f k8s/frontend/deployment.yaml -n myapp
    kubectl apply -f k8s/frontend/service.yaml -n myapp
    ```
5.  **Ingress-Ressource (nachdem die Services erstellt wurden):**
    ```bash
    kubectl apply -f k8s/ingress.yaml -n myapp
    ```

Alternativ können alle YAML-Dateien in einem Verzeichnis auf einmal angewendet werden (wobei `kubectl` versucht, die Reihenfolge intelligent zu wählen, aber die explizite Reihenfolge ist sicherer für Abhängigkeiten wie Secrets und ConfigMaps):

```bash
kubectl apply -f k8s/database -n myapp
kubectl apply -f k8s/backend -n myapp
kubectl apply -f k8s/frontend -n myapp
kubectl apply -f k8s/ingress.yaml -n myapp # Ingress zuletzt oder nach den Services
```

Oder für das gesamte `k8s`-Verzeichnis (rekursiv, aber die Reihenfolge ist dann weniger kontrolliert):

```bash
kubectl apply -R -f k8s -n myapp
```

## Zugriff auf die Anwendung

Nachdem alle Pods laufen und der Ingress konfiguriert ist:

1.  **Stelle sicher, dass dein Ingress Controller eine externe IP-Adresse hat:**

    ```bash
    kubectl get services -n <namespace-des-ingress-controllers> # z.B. ingress-nginx oder default
    ```

    Suche nach dem Service des Ingress Controllers (oft Typ `LoadBalancer`) und seiner `EXTERNAL-IP`.

2.  **Konfiguriere deinen lokalen Host-Eintrag (für lokale Entwicklung mit `myapp.local`):**
    Füge deiner lokalen `hosts`-Datei (z.B. `C:\Windows\System32\drivers\etc\hosts` unter Windows oder `/etc/hosts` unter Linux/macOS) einen Eintrag hinzu:

    ```
    <EXTERNE-IP-DES-INGRESS-CONTROLLERS> myapp.local
    ```

    Wenn du Docker Desktop verwendest, ist die externe IP oft `localhost` oder `127.0.0.1`.

3.  **Greife auf die Anwendung zu:**
    Öffne `http://myapp.local` in deinem Browser.
    - Anfragen an `http://myapp.local/` sollten das Frontend anzeigen.
    - Anfragen vom Frontend an `/api/notes` (intern umgeleitet zu `http://myapp.local/api/notes`) sollten vom Backend verarbeitet werden.

**Alternativer Zugriff (ohne Ingress, z.B. über Frontend Service vom Typ `LoadBalancer` oder `NodePort`):**
Wenn du keinen Ingress verwendest und dein `frontend-service` vom Typ `LoadBalancer` ist:

```bash
kubectl get services -n myapp
```

Suche nach dem `frontend-service` und seiner `EXTERNAL-IP`. Wenn `EXTERNAL-IP` auf `<pending>` steht, warte einige Minuten. Bei lokalen Clustern wie Minikube verwende `minikube service frontend-service -n myapp --url`. Für Docker Desktop ist der Dienst oft unter `localhost:<PORT>` erreichbar, wobei `<PORT>` der Port ist, der in der `kubectl get services` Ausgabe für den `frontend-service` angezeigt wird.

## Kubernetes Monitoring (Metrics Server, Prometheus & Grafana)

Wenn ein Monitoring-Stack im Kubernetes-Cluster installiert ist (z.B. Kubernetes Metrics Server und der `kube-prometheus-stack` im Namespace `monitoring`), kannst du wie folgt auf die Metriken und Dashboards zugreifen:

### 1. Kubernetes Metrics Server

Stellt grundlegende Ressourcenmetriken (CPU, Speicher) für Pods und Nodes bereit. Diese werden von `kubectl top` verwendet.

- **Überprüfung (nachdem der Metrics Server installiert und bereit ist):**
  ```bash
  kubectl top nodes
  kubectl top pods -n myapp # Für die Pods dieser Anwendung
  kubectl top pods --all-namespaces # Für alle Pods in allen Namespaces
  ```

### 2. Prometheus Dashboard

Prometheus sammelt detaillierte Metriken vom Cluster und den Anwendungen.

- **Port-Forward zum Prometheus-Service:**
  (Der Service-Name kann je nach Installation variieren, `prometheus-kube-prometheus-prometheus` ist üblich für den `kube-prometheus-stack`)
  ```bash
  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
  ```
- **Zugriff:**
  Öffne `http://localhost:9090` in deinem Browser.
  Hier kannst du Metriken abfragen (PromQL) und den Status der Scrape-Ziele einsehen.

### 3. Grafana Dashboard

Grafana visualisiert die von Prometheus gesammelten Metriken in anpassbaren Dashboards.

- **Admin-Passwort für Grafana abrufen:**
  (Der Secret-Name kann je nach Installation variieren, `prometheus-grafana` ist üblich für den `kube-prometheus-stack`. Der Benutzername ist `admin`.)
  ```bash
  kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
  ```
- **Port-Forward zum Grafana-Service:**
  (Der Service-Name kann je nach Installation variieren, `prometheus-grafana` ist üblich)
  ```bash
  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
  ```
  (Der Grafana-Service im Chart lauscht oft intern auf Port 80, wir leiten ihn auf unseren lokalen Port 3000 weiter).
- **Zugriff:**
  Öffne `http://localhost:3000` in deinem Browser.
  Melde dich mit dem Benutzernamen `admin` und dem zuvor abgerufenen Passwort an.
  Der `kube-prometheus-stack` installiert in der Regel bereits einige nützliche Dashboards zur Überwachung des Kubernetes-Clusters. Diese findest du unter "Dashboards" oder "Browse".

**Hinweis zum Monitoring-Stack:**
Die Befehle setzen voraus, dass der Monitoring-Stack im Namespace `monitoring` installiert wurde und die Service-Namen den gängigen Konventionen des `kube-prometheus-stack` Helm-Charts entsprechen. Passe die Namespace- und Service-Namen bei Bedarf an deine spezifische Installation an. Die Installation des Monitoring-Stacks selbst ist nicht Teil dieser Anwendungs-YAMLs, sondern erfolgt separat (z.B. Metrics Server über `kubectl apply`, Prometheus/Grafana über Helm).

## Wichtige Hinweise

- **Datenpersistenz:** Die Verwendung eines `PersistentVolumeClaim` (PVC) für die Datenbank wird dringend empfohlen, um Datenverlust bei Pod-Neustarts zu vermeiden. Ohne PVC (mit `emptyDir`) gehen alle Datenbankinhalte verloren.
- **Secrets:** Das `database/secret.yaml` enthält Platzhalter oder Beispielwerte. Stelle sicher, dass du sichere, Base64-kodierte Passwörter verwendest und die Datei entsprechend anpasst oder das Secret manuell erstellst.
- **Images:** Stelle sicher, dass die referenzierten Docker-Images (`mephisto1339/frontend-image:latest`, `mephisto1339/backend-image:latest`) für deinen Kubernetes-Cluster erreichbar sind.
- **Ingress Controller:** Für die Verwendung von `ingress.yaml` muss ein Ingress Controller im Cluster aktiv sein.

## Troubleshooting

- **Pods nicht bereit (`Pending`, `CrashLoopBackOff`, `Error`):**
  ```bash
  kubectl get pods -n myapp
  kubectl describe pod <pod-name> -n myapp
  kubectl logs <pod-name> -n myapp
  kubectl logs <pod-name> -c <container-name> -n myapp # Falls mehrere Container im Pod
  kubectl logs <pod-name> -c <container-name> -n myapp --previous # Für gecrashte Container
  ```
- **Service nicht erreichbar:**
  Überprüfe die Selektoren im Service und die Labels der Pods.
  Überprüfe die Endpunkte des Services: `kubectl get endpoints <service-name> -n myapp`.
- **Ingress-Probleme:**
  Überprüfe die Ingress-Konfiguration: `kubectl describe ingress myapp-ingress -n myapp`.
  Überprüfe die Logs des Ingress Controllers: `kubectl logs -l <label-des-ingress-controller-pods> -n <namespace-des-ingress-controllers>`.
- **Metrics Server Probleme (`kubectl top nodes` schlägt fehl):**
  Überprüfe den Status und die Logs des `metrics-server` Pods im `kube-system` Namespace. Für lokale Setups wie Docker Desktop muss oft das `metrics-server` Deployment mit dem Argument `--kubelet-insecure-tls` gepatcht werden.
  ```bash
  kubectl get pods -n kube-system | grep metrics-server
  kubectl logs -n kube-system <metrics-server-pod-name>
  # Patch-Befehl (falls nötig):
  # kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
  ```