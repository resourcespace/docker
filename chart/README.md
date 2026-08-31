# resourcespace

A Helm chart for resourcespace

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
# Standard Helm install
$ helm install  my-release resourcespace

# To use a custom namespace and force the creation of the namespace
$ helm install my-release --namespace my-namespace --create-namespace resourcespace

# To use a custom values file
$ helm install my-release -f my-values.yaml resourcespace
```

See the [Helm documentation](https://helm.sh/docs/intro/using_helm/) for more information on installing and managing the chart.

## Configuration

The following table lists the configurable parameters of the resourcespace chart and their default values.

| Parameter                                                 | Default                    |
| --------------------------------------------------------- | -------------------------- |
| `mariadb.imagePullPolicy`                                 | `IfNotPresent`             |
| `mariadb.persistence.mariadb.accessMode[0].value`         | `ReadWriteOnce`            |
| `mariadb.persistence.mariadb.enabled`                     | `true`                     |
| `mariadb.persistence.mariadb.size`                        | `1Gi`                      |
| `mariadb.persistence.mariadb.storageClass`                | `-`                        |
| `mariadb.replicas`                                        | `1`                        |
| `mariadb.repository.image`                                | `mariadb`                  |
| `mariadb.repository.tag`                                  | ``                         |
| `mariadb.serviceAccount`                                  | ``                         |
| `resourcespace.imagePullPolicy`                           | `IfNotPresent`             |
| `resourcespace.ingress.class`                             | `-`                        |
| `resourcespace.ingress.enabled`                           | `false`                    |
| `resourcespace.ingress.host`                              | `mywebsite.com (optional)` |
| `resourcespace.ingress.path`                              | `/`                        |
| `resourcespace.ingress.tls.enabled`                       | `true`                     |
| `resourcespace.ingress.tls.secretName`                    | ``                         |
| `resourcespace.persistence.filestore.accessMode[0].value` | `ReadWriteOnce`            |
| `resourcespace.persistence.filestore.enabled`             | `true`                     |
| `resourcespace.persistence.filestore.size`                | `1Gi`                      |
| `resourcespace.persistence.filestore.storageClass`        | `-`                        |
| `resourcespace.replicas`                                  | `1`                        |
| `resourcespace.repository.image`                          | ``                         |
| `resourcespace.repository.tag`                            | ``                         |
| `resourcespace.serviceAccount`                            | ``                         |


