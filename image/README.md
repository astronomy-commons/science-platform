# axs-notebook

Create a Docker image for the singleuser server based. Integrates Jupyter notebooks with AXS/Spark.

Build and deploy to your own repository:
```
make build # builds image jupyter-axs:latest
docker tag jupyter-axs:latest <repo>/<image>:<tag>
docker push <repo>/<image>:<tag>
```