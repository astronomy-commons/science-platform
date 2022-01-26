# Singleuser Server

Create a Docker image for the singleuser server. 

Build and deploy to your own repository:
```
make build # builds image astronomycommons/public-hub-singleuser:latest
docker tag astronomycommons/public-hub-singleuser:latest <repo>/<image>:<tag>
docker push <repo>/<image>:<tag>
```