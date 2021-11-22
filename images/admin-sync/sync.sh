# Get users
users_and_admins=$(curl -s -H "Authorization: token ${JUPYTERHUB_API_TOKEN}" hub:8081/hub/api/users | jq -r '.[] | "\(.name) \(.admin)"')
