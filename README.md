
# Repository Contents

- `chart`: The Helm chart for deploying the JupyterHub on Kubernetes.
- `cluster`: The scripts for creating a Kubernetes cluster on AWS EKS.
- `scripts`: Scripts for deploying the JupyterHub on the EKS cluster.
- `image`: The Dockerfile for the singleuser notebook server.

# Deploying

Creating the cluster
```
eksctl create cluster -f ./cluster/eksctl_config.yaml
```

Create a secret token to secure the JupyterHub Proxy API:
```
token=$(openssl rand -hex 32)
printf "jupyterhub:\n  proxy:\n    secretToken: ${token}\n" >> values-customize.yaml
```

Deploy the JupyterHub Helm chart on the EKS cluster:
```
export NAMESPACE=hub
export RELEASE=hub
./scripts/deploy.sh
```

(Optional) Once the deployment is ready, intialize the Hive metastore to add our tables stored on S3:
```
export NAMESPACE=hub
./scripts/init_metastore.sh
```

(Optional) Once the deployment is ready, update DNS records on Route 53 for a domain you own to point to the JupyterHub:
```
export HUB_FQDN=public-hub.astronomycommons.org
./scripts/update_dns.sh
```

# Customizing

Add your own image by customizing the file `values-customize.yaml`:

```
# file: values-customize.yaml
jupyterhub:
    singleuser:
        image:
            name: <your-image>
            tag: <your-image-tag>
```

Enable HTTPS with letsencrypt:
```
# file: values-customize.yaml
proxy:
    https:
      enabled: true
      letsencrypt:
        contactEmail: <your-email>
      hosts:
      - <your-domain-name>
```

Add AWS access keys for your AWS account with:
```
# file: values-customize.yaml
jupyterhub:
    singleuser:
        extraEnv:
            AWS_ACCESS_KEY_ID: <AWS_ACCESS_KEY_ID>
            AWS_SECRET_ACCESS_KEY: <AWS_SECRET_ACCESS_KEY>
            AWS_DEFAULT_REGION: <AWS_DEFAULT_REGION>
```

Add requester pays headers to spark so you can access our data on your own deployments:
```
# file: values-customize.yaml
spark-defaults.conf:
    999-requester-pays: |
        spark.hadoop.fs.s3a.requester-pays.enabled=true
```

Add GitHub organization authentication. First, generate a token to encrypt the `auth_state` returned from GitHub: `token=$(openssl rand -hex 32)`

```
# file: values-customize.yaml
jupyterhub:
  hub:
    extraEnv:
      JUPYTERHUB_CRYPT_KEY: ${token}
    config:
      Authenticator:
        admin_users:
        - <your-user-name>
      GitHubOAuthenticator:
        allowed_organizations:
        - <your-github-organziation>
        client_id: <client-id>
        client_secret: <client-secret>
        oauth_callback_url: <hub-fqdn>/hub/oauth_callback
      JupyterHub:
        admin_access: true
        authenticator_class: github
      OAuthenticator:
        scope:
        - read:user
        - read:org
```

# Admin users

# SSH

By default, a SSH "jump host" is deployed with this chart to allow users to use `scp` and `sftp` to copy files to the NFS. In addition, each notebook server starts its own SSH service, allowing users to access their notebook servers using `ssh` via the jump host.

If a user wants to utilize this, they should perform the following steps:
1. Launch their notebook server.
2. Start a terminal and open the file `~/.ssh/authorized_keys` with a text editor.
3. Add your public key as a new line in this file.
4. Edit the file `~/.ssh/config` on your local machine to include the following:
```
Host jhub-ssh
    User <username>
    Hostname <ssh-hostname>

Host jhub
    User <username>
    Hostname <host-prefix>-<username>.notebooks
    ProxyJump jhub-ssh
```
Administrators should set and provide to you the values for `<ssh-hostname>` (e.g. `ssh.demo.dirac.dev`) and the `<host-prefx>` (e.g. `jupyter` or `demo`). `<username>` should be set to your username on the JupyterHub.
5. On your local machine, ssh to your running notebook server: `ssh jhub`. 

# Build on this Helm chart

```
helm repo add science-platform https://hub.astronomycommons.org/
helm repo update
```