#!/bin/bash

# Switch to deployment directory and load the config
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$(dirname $DIR)"
. scripts/common.sh

test_dependency jq
test_dependency kubectl
test_dependency aws

test_var NAMESPACE
test_var HUB_FQDN

# host and the domain
HOST=$(echo "$HUB_FQDN" | cut -d . -f 1)
DOMAIN=$(echo "$HUB_FQDN" | cut -d . -f 2-)

# Find our external IP. This may take a few minutes
HUBIP=
hdr=
while [[ -z "$HUBIP" ]]; do
	# load balancer may provision an ip or a DNS name
	# alternate between checking for an ip field vs hostname
	HUBIP=$(kubectl --namespace="$NAMESPACE" get svc proxy-public --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
	[[ -n "$HUBIP" ]] || HUBIP=$(kubectl --namespace="$NAMESPACE" get svc proxy-public --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
	[[ -n "$HUBIP" ]] && break

	if [[ -z $hdr ]]; then
		echo -n "Awaiting assignment of proxy IP (may take 2-3 minutes)... "
		hdr=1
	else
		echo -n "."
	fi
	sleep 1
done
[[ $hdr == 1 ]] && echo " done."

hosted_zone_id=$(aws --output=json route53 list-hosted-zones | jq -r --arg DOMAIN "${DOMAIN}." ' .HostedZones | .[] | select(.Name==$DOMAIN) | .Id ')

resources=$(aws --output=json route53 list-resource-record-sets --hosted-zone-id $hosted_zone_id)
record=$(echo "$resources" | jq --arg  HUB_FQDN "${HUB_FQDN}." ' .ResourceRecordSets | .[] | select(.Name==$HUB_FQDN and .Type=="A") ')

alias_hosted_zone_id=$(echo "$record" | jq ' .AliasTarget.HostedZoneId ')
alias_dns_name=$(echo "$record" | jq ' .AliasTarget.DNSName ')

evaluate_target_health=$(echo "$record" | jq ' .AliasTarget.EvaluateTargetHealth ')
# remove preceeding "dualstack.
CURIP="${alias_dns_name#\"dualstack.}"
# remove trailing ."
CURIP="${CURIP%.\"}"

if [[ "$CURIP" == "$HUBIP" ]]; then
	echo "DNS for $HUB_FQDN already points to the correct IP ($CURIP)."
	exit
fi

if [[ -n $record ]]; then
	# delete old A record
	delete_request=$(cat <<-EOF
	{
		"Comment": "Remove alias A record",   
		"Changes": [
			{
			"Action": "DELETE",
				"ResourceRecordSet": {
					"Name": "${HUB_FQDN}.",
					"Type": "A",
					"AliasTarget": {
						"HostedZoneId": ${alias_hosted_zone_id},
						"DNSName": ${alias_dns_name},
						"EvaluateTargetHealth": ${evaluate_target_health}
					}
				}
			}
		]
	}
	EOF
	)
	response=$(aws --output=json route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch "$delete_request")
fi

# create new record
new_alias_name="\"dualstack.${HUBIP}\""
evaluate_target_health="false"
load_balancer_hosted_zone=$(aws --output=json elb describe-load-balancers | jq --arg HUBIP "$HUBIP" ' .LoadBalancerDescriptions | .[]  | select(.DNSName==$HUBIP) | .CanonicalHostedZoneNameID ')
create_request=$(cat <<-EOF
	{
		"Comment": "Create alias A record",   
		"Changes": [
			{
			"Action": "CREATE",
				"ResourceRecordSet": {
					"Name": "${HUB_FQDN}.",
					"Type": "A",
					"AliasTarget": {
						"HostedZoneId": ${load_balancer_hosted_zone},
						"DNSName": ${new_alias_name},
						"EvaluateTargetHealth": ${evaluate_target_health}
					}
				}
			}
		]
	}
EOF
)
response=$(aws --output=json route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch "$create_request")

# restart autohttps pods since their DNS queries may not have been resolved
kubectl --namespace="$NAMESPACE" scale deployment autohttps --replicas=0
kubectl --namespace="$NAMESPACE" scale deployment autohttps --replicas=1