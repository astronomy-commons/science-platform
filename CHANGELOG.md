# 0.6.3

Version 0.6.3 release of the public-hub Helm chart. Please run `helm repo update`. 
- Added packages to the SSH image: `iputils-ping traceroute netcat sudo`. 
- Added the `jovyan` user to the SSH image. This allows ssh to work on out of the box deployments with the `jovyan` user.
- Updated the SSH deployment to include label `hub.jupyter.org/network-access-singleuser: "true"` so that traffic from the SSH pod can route to the notebook pods when Kubernetes network policies are enforced.
- Updated the `values.yaml` to specify `networkPolicy.allowedIngressPorts=[22]` to allow ingress traffic on port 22. This allows SSH traffic when Kubernetes network policies are enforced.
- Updated the `mariadb` chart dependency version constraint to `>=9.3.5` since `9.3.5` is no longer available. Updates the dependency to `11.4.4`.
- Added configuration to the `mariadb` chart in `values.yaml` to create an Init Container that downloads Hive schema init scripts as neither `wget` nor `curl` were available in the updated MariaDB image packaged with version `11.4.4` of the `mariadb` Helm chart.
- Added Carl L Christofferson as maintainer of the chart.
- Added CHANGELOG.md to the repository for tracking this update and future changes.
- Added `public-hub-0.6.3.tgz` Helm chart and updated `index.yaml` to include the new version