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

- [k3d](https://k3d.io/v5.4.6/) (**optional**, only when dealing with `local` engine)
- [devspace](https://www.devspace.sh/docs/getting-started/introduction) (**optional**, only for Kubernetes development)

For people that are interested about running the devkit using the `openstack` engine, you will need to have a credentials file.

## Usage

To start a new devkit, run : 

```bash
# valid engines are: local, openstack
devkit.sh start <engine>
```

> Note: when using the `openstack` engine, source the credentials file to allow Terraform to auto-configure the provider.
> ```
> source /path/to/credentials.rc
> ```

To stop it (**be careful, all data will be lost !**), run : 

```bash
# valid engines are: local, openstack
devkit.sh stop <engine>
```

Once done, the Polyflix API should be accessible on the following URL: http://polyflix.local/api. You only need to run the front-end locally, by using the `devkit` environment. **Please refer to the front-end documentation for more information.**

Below are the applications that are exposed :

- http://kibana.polyflix.local
- http://keto.polyflix.local
- http://keycloak
- http://minio
- http://console.minio.polyflix.local
- http://polyflix.local/api

Some data was provisioned for you during the devkit bootstrap. You should be able to login using one of the following accounts through the Polyflix front-end : 

- Email: **administrator@polyflix.local** / Password: **administrator**
- Email: **contributor@polyflix.local** / Password: **contributor**
- Email: **member@polyflix.local** / Password: **member**



