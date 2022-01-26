# SSH Jump Host

Create a Docker image for the SSH Jump host.

Build and deploy to your own repository:
```
make build # builds image astronomycommons/jupyterhub-ssh:latest
docker tag astronomycommons/jupyterhub-ssh:latest <repo>/<image>:<tag>
docker push <repo>/<image>:<tag>
```