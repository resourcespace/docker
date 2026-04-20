# ResourceSpace Helm Chart

Deploys [ResourceSpace](https://www.resourcespace.com/) (Digital Asset Management) on
OpenShift with:

- **ResourceSpace** web app as a Kubernetes `Deployment`
- **MariaDB** as an in-cluster `StatefulSet`
- **External NFS storage** for both the filestore and MariaDB data
- **OpenShift Route** with edge TLS termination

---

## Prerequisites

| Requirement | Notes |
|---|---|
| OpenShift 4.x | Tested on 4.12+ |
| Helm 3.x | `helm version` |
| `oc` CLI logged in | `oc whoami` |

---

## Image Build
The image should be built from the official source repository and pushed to an available registry
### Source
```bash
git clone git@github.com:resourcespace/docker.git # for SSH clone
cd docker
```
### OpenShift Modifications
The upstream image runs apache on port 80 as root, which OpenShift's `restricted-v2` SSC does not permit. Three files should be added/modified before building:
`ports.conf` - Tells Apache to listen on port 8080 instead:
```bash
Listen 8080
```
`000-default.conf` - vhost on port 8080 with correct directory permissions:
```bash
ServerName resourcespace

<VirtualHost *:8080>
    DocumentRoot /var/www/html

    <Directory /var/www/>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```
`entrypoint.sh` - skips cron (no `/var/run` write access), redirects apache runtime files to `/tmp` which is writable by any UID:
```bash
#!/bin/bash
set -e

mkdir -p /tmp/apache2/run /tmp/apache2/lock /tmp/apache2/log
export APACHE_RUN_DIR=/tmp/apache2/run
export APACHE_LOCK_DIR=/tmp/apache2/lock
export APACHE_LOG_DIR=/tmp/apache2/log
export APACHE_PID_FILE=/tmp/apache2/run/apache2.pid

exec apachectl -D FOREGROUND
```
`Dockerfile` - additions to upstream:
```bash
# Replace Apache configs before the SVN checkout
COPY ports.conf         /etc/apache2/ports.conf
COPY 000-default.conf   /etc/apache2/sites-enabled/000-default.conf

# Make runtime dirs world-writable for arbitrary UID
RUN mkdir -p /var/run/apache2 /var/lock/apache2 /var/log/apache2 \
    && chmod -R 777 /var/run/apache2 /var/lock/apache2 /var/log/apache2 \
    && chmod -R 777 /var/www/html

EXPOSE 8080
```
### Build and Push
```bash
docker build -t <your registry>/<your repository>:<tag> .
docker push <your registry>/<your repository>:<tag>
```

## Helm Chart
### Config before deploying
In `values.yaml`:
```yaml
resourcespace:
  image: <your-image-registry>/<image-repository>
  tag: <image-tag>
  pullPolicy:

  hostname: <your-application-hostname> # Example: resourcespace.apps.mycluster.example.com
mariadb:
  auth:
    rootPassword: "" # set in advance or at runtime
    database: "resourcespace"
    username: "resourcespace"
    password: "" # set in advance or at runtime
```
### Install
```bash
oc new-project <namespace> # skip if namespace already exists
helm install resourcespace . -n <namespace> # run in dir where values.yaml is

# install with secret creation
helm install resourcespace . -n <namespace> \
  --set mariadb.auth.rootPassword=<secure-password> \
  --set mariadb.auth.password=<secure-password>
```

### Upgrade
```bash
helm upgrade resourcespace . -n <namespace> # also where values.yaml is
```

### Uninstall
```bash
helm uninstall resourcespace -n <namespace>
```

## Run Setup Wizard

On first deployment, navigating to the route URL shows the ResourceSpace setup wizard.

### Known Issue — Base URL Check

The wizard validates the base URL by fetching `license.txt` from it. This fails when
using the public route URL because the pod cannot route back to itself through the
external ingress. **Workaround:** enter the internal service URL during setup:
```
http://resourcespace
```
The entrypoint automatically corrects this to the public route URL on every startup
via the `RS_BASEURL` environment variable — no manual fix needed.

### Database Settings

| Field | Value |
|---|---|
| MySQL server | `resourcespace-mariadb` |
| MySQL port | `3306` |
| MySQL database | value of `mariadb.auth.database` in values.yaml |
| MySQL username | value of `mariadb.auth.username` in values.yaml |
| MySQL password | value of `mariadb.auth.password` in values.yaml |
| MySQL binary path | *(leave empty)* |
| Filestore path | `/var/www/html/filestore` |

### Persisting Configuration

After completing the wizard, restart the pod to persist `config.php` and apply the
correct public route URL automatically:

```bash
oc rollout restart deployment/resourcespace -n <namespace>
```

The entrypoint saves `config.php` to the filestore PVC on first run and restores it
with the correct `RS_BASEURL` on every subsequent restart.