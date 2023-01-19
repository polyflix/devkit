# Polyflix Devkit

This repository contains configurations and scripts required to empower a Polyflix developer environment (a.k.a, **devkit**). It allow maintainers and contributors to easily **run** and **develop** the platform on a Kubernetes cluster, without having to worry about the deployment and configuration steps.

## Limitations

**Currently, the devkit can only be used on a Unix based operating system, such as Ubuntu, Debian or MacOS.**

When dealing with `local` engine for the Kubernetes cluster, performance may be considerably decreased than a cloud-provider based Kubernetes cluster such as `openstack`, because of the underlying usage of [k3d](https://k3d.io/v5.4.6/).

## Requirements

- [kubectl](https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/)
- [helm](https://helm.sh/)
- [Helmfile](https://github.com/helmfile/helmfile)
- [Helm-diff](https://github.com/databus23/helm-diff)
- [Terraform](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform)
- [k3d](https://k3d.io/v5.4.6/) (**optional**, only when dealing with `local` engine)
- [devspace](https://www.devspace.sh/docs/getting-started/introduction) (**optional**, only for Kubernetes development)

For people that are interested about running the devkit using the `openstack` engine, you will need to have a credentials file.

## Usage

To start a new devkit, run : 

```bash
# valid engines are: local, openstack
./devkit.sh start <engine>
```

> Note: when using the `openstack` engine, source the credentials file to allow Terraform to auto-configure the provider.
> ```
> source /path/to/credentials.rc
> ```

To stop it (**be careful, all data will be lost !**), run : 

```bash
# valid engines are: local, openstack
./devkit.sh stop <engine>
```

Once done, the Polyflix API should be accessible on the following URL: http://polyflix.local/api. You only need to run the front-end locally, by using the `devkit` environment. **Please refer to the front-end documentation for more information.**

Below are the applications that are exposed :

- http://kibana.polyflix.local
- http://keto.polyflix.local
- http://keycloak
- http://minio
- http://console.minio.polyflix.local
- http://polyflix.local/api

## Develop inside Kubernetes

To make your developer journey for Polyflix easier, you can add an alias to the `devspace` command to always use the good devkit cluster : 

```bash
echo "alias devspace=\"KUBECONFIG=/absolute/path/to/devkit/outputs/k8s.yml\" devspace" >> ~/.zshrc
```

Every project has a `devspace.yaml` file. To enable development in the cluster, just run the command : 

```bash
devspace dev
```

This will open a remote shell inside a devspace pod in the cluster. You can now use your commands to run the project, such as `mvn spring-boot:run` or `npm start`.

To reset the service to the default image, exit the remote shell and run :

```bash
devspace purge
```

## Accounts

### Polyflix

- Email: **administrator@polyflix.local** / Password: **administrator**
- Email: **contributor@polyflix.local** / Password: **contributor**
- Email: **member@polyflix.local** / Password: **member**

### Keycloak

- Username: **polyflix**
- Password: **polyflix**

### PostgreSQL

- Username: **postgres**
- Password: **polyflix**

### MinIO

- Username: **polyflix**
- Password: **polyflix**
