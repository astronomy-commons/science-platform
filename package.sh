# Create a new chart archive versioned
# Chart version depends on the value in Chart.yaml
# archives added to docs/ and the index.yaml there
# determine what versions of this Helm chart are publicly available
helm dependency update chart/
helm package chart/
mv public-hub*.tgz docs/.
helm repo index docs/.