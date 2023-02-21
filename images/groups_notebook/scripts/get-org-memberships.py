#!/usr/bin/env python
#
# Grab organization membership information from GitHub, and
# print it out as "<org-name> <org-id>", one per line.
#
# Must have GitHub auth token in $GH_TOKEN envvar
#

import os, argparse
from github import Github

parser = argparse.ArgumentParser(description='Fetch organization membership info. Authentication token must be in the GH_TOKEN environmental variable.')
parser.add_argument('what', choices=['member', 'owner'], help='which info to return')
args = parser.parse_args()

# this script expects the access token to be given in an environment variable
token = os.environ["GH_TOKEN"]
g = Github(token)

# find our identity, and our organizations
me = g.get_user()
orgs = me.get_orgs()

if args.what == 'member':
	for org in orgs:
		print(org.login, org.id)
elif args.what == 'owner':
	for org in orgs:
		if any(member.login == me.login for member in org.get_members(role='admin')):
			print(org.login, org.id)
