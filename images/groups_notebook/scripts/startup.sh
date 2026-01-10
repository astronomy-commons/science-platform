#
# Startup script run as 'root' by start.sh
#
# This is run very early in the execution of start.sh, which allows us to hijack
# much of the (buggy) functionality that goes on there.
#
#set -x

#
# Prepare the key directories
#

SVC_HOMES="/home/owners"
GROUP_HOMES="/lincc/groups"
DATA_DIR="/lincc/data"
SHARED_DIR="/lincc/shared"
SECRET="/lincc/.system"

# FIXME: this should be a direct mount
mkdir -p /home/_lincc
ln -s /home/_lincc /lincc

# HACK: $SECRET is used to exchange user/group info with the NFS server
mkdir -p "$SECRET"; chmod 700 "$SECRET"
ls -l "$SECRET"

# Make sure these exist, and that the ownership is correct.
mkdir -p "$SVC_HOMES"		# owned by root.root
mkdir -p "$GROUP_HOMES"		# owned by root.root

[[ ! -e "$DATA_DIR"   ]] && { mkdir -p "$DATA_DIR";   chown admin:admin "$DATA_DIR"; }						# globally shared data; owned by admin.admin
[[ ! -e "$SHARED_DIR" ]] && { mkdir -p "$SHARED_DIR"; chown root.root "$SHARED_DIR"; chmod u+rwx,g+rwx,o+rwxt "$SHARED_DIR"; }	# globally shared dir, set up with the sticky bit so anyone can write

##
## Create our user
##
H="/home/$NB_USER"

groupadd -g "$NB_UID" "$NB_USER"

test -e "$H" && CREATE_HOME="-M" || CREATE_HOME="-m"   # Don't create the home directory if it already exists
useradd $CREATE_HOME -s /bin/bash -u "$NB_UID" -g "$NB_UID" -G users "$NB_USER"
[[ "$CREATE_HOME" == "-m" ]] && chmod 770 "$H"         # If we just created the home dir, set private default permissions

cd "$H"

# prevent start.sh from messing with groups
export NB_GID="$NB_UID"

##
## Create groups for all organizations we're a member of
##

info()
{
	# Use this to print informational messages. Will prepend the script
	# and function name to any passed arguments.

	echo "${BASH_SOURCE[1]}::${FUNCNAME[1]}: ""$@" 1>&2
}

_safe_python()
{
	# Invoke the version of Python safe to be run by root (i.e., one
	# which is not under other users' control (e.g. admins own
	# /opt/conda, so malicious admin can elevate themselves to root if
	# we accidentally run anything from there).
	/usr/bin/python3 "$@"
}

_normalize_username()
{
	# Default JupyterHub GitHub OAuthenticator turns all usernames to lowercase
	# If you change this for your hub, you mush change this script as well.

	# Note: this only works with Bash 4+
	echo "${1,,}"
}

create_org_groups()
{
	info entered
	(
		# temporary file where we'll accumulate group information
		mkdir -p "$SECRET"/{tmp,groups}
		TMPFN="$SECRET/tmp/${NB_USER}.${NB_UID}"
		rm -f "$TMPFN"

		groups=()
		while IFS=" " read -r org_name org_id remainder; do
			org_name=$(_normalize_username "${org_name}")
			H="${SVC_HOMES}/${org_name}"
			G="${GROUP_HOMES}/${org_name}"
			E="${G}/envs"

			# create the corresponding group
			groupadd -g "${org_id}" "${org_name}"

			# create and configure the group service account. 
			# This account owns all files that group members
			# shouldn't accidentally delete.
			#
			# Rant: Ordinarily, this account's primary group would be just the ${org_name} group.
			# We'd set the umask to 002, thus making any files/dirs created by the account unwritable
			# by regular members of the group (i.e., files/dirs created by the service users would
			# typically have rwxr-xr-x permissions). This would satisfy the goal of preventing accidental
			# deletion of files by group members.
			#
			# Alas... Enter the bonkers decision at https://github.com/conda/conda-build/issues/1904
			# where conda folks decided to explicitly set g+w permissions on everything one installs, thus
			# breaking security in systems configured with USERGROUPS=no (i.e., where users share the
			# primary group). This means that the permissions are rwxrwxr-x, no matter the umask, meaning
			# that any group member can delete these directories. That this type of decision could have been
			# made me lost faith in Anaconda Inc's security proweness... $DEITY knows what else that group
			# may be doing on the backend of anaconda.org (how safe are those files?). /Rant off
			# 
			# To work around the insanity above, we create a special group for the service user. We give
			# it a gid of 1Bn + ${org_id}. The number of IDs on GH seems to be growing at ~2M/month (1.66,
			# to be exact; checked on Oct/19/2021). The largest current ID is around 91.8M. At that
			# rate, for the IDs to reach 1Bn it will take ~37 years. Though I still feel the "solution"
			# is yucky and should be fixed (w. a database of mappings), we should be fine for awhile.
			#
			svc_group_id=$((org_id + 1000000000))
			svc_group_name="${org_name}_svc"
			groupadd -g "${svc_group_id}" "${svc_group_name}"
			if [[ -e "$H" ]]; then
				# Home exists; just create the user.
				useradd -M -b "$SVC_HOMES" -s /bin/bash -u "${org_id}" -g "${svc_group_id}" -G users,"${org_name}" "${org_name}"
			else
				# Home doesn't exist; create the user, configure permissions
				useradd -m -b "$SVC_HOMES" -s /bin/bash -u "${org_id}" -g "${svc_group_id}" -G users,"${org_name}" "${org_name}"

				chmod o-rwx "$H"

				# change the default environment location for the service account
				cat > "$H/.condarc" <<-EOT
					envs_dirs:
					  - $E
				EOT
			fi
			echo "${org_name} ${org_id} ${svc_group_name} ${svc_group_id}" >> "$TMPFN"

			# now create the org directory if it doesn't exist and make it owned
			# by the service account. this is for common data and software shared
			# by the group.
			#
			# The group directory will have the sticky bit set. This will allow anyone
			# in the group to create new files/folders, but only the owner of the file
			# and the group service account to delete or rename them. This adds a layer
			# of safety. It also explains why we can have the envs/ directory here, w/o
			# worrying a group member may delete it.
			if [[ ! -e "$G" ]]; then
				mkdir -p "$G"
				chown "${org_name}":"${org_name}" "$G"
				chmod u=rwx,g=rwxs,o=,o+t "$G"
			fi

			# create the environments directory, and make sure it's owned by the
			# service group
			if [[ ! -e "$E" ]]; then
				mkdir -p "$E"
				chown "${org_name}":"${svc_group_name}" "$E"
				chmod 755 "$E"
			fi

			info "added and configured group ${org_name} with service account ${org_name}:${svc_group_name}"
			groups+=("${org_name}")
		done < <(_safe_python -u /usr/local/bin/get-org-memberships.py member)  # note: this construct ensures the while loop doesn't launch in a subshell (thus retaining $groups)

		# add the user to all groups
		groups_comma=$(IFS=, ; echo "${groups[*]}")
		usermod -a -G "${groups_comma}" "$NB_USER"
		info "added ${NB_USER} to ${groups_comma}"

		# update the NFS-server group database (atomic move)
		mv "$TMPFN" "$SECRET/groups/${NB_USER}.${NB_UID}"
		du -a "$SECRET" 1>&2

		# return the space-delimited list of groups
		echo "${groups[@]}"
	)
}

create_service_accounts()
{
	(
		_safe_python -u /usr/local/bin/get-org-memberships.py owner |
		while IFS=" " read -r org_name org_id remainder; do
			org_name=$(_normalize_username "${org_name}")
			# allow our user to access it with sudo
			S="/etc/sudoers.d/svc-${org_name}"
			echo "$NB_USER  ALL=(${org_name})      NOPASSWD: ALL" > "$S"

			info "service account access for ${org_name} added to sudoers in $S";
		done
	)
}

# FIXME: we could use `conda config` commands
_echo_condarc()
{
	echo "$@" >> /opt/conda/.condarc
}

set_conda_env_paths()
{
	[[ $# -eq 0 ]] && return

	# make sure the user's home dir is first, so it's picked up as
	# the default place to install user environments
	_echo_condarc "envs_dirs:"
	_echo_condarc '  - $HOME/.conda/envs'

	# append all envs_dirs
	local grp
	for grp in "$@"; do
		_echo_condarc "  - /lincc/groups/$grp/envs"
	done
}

# Mirror the user's GH organizations into groups
groups=$(create_org_groups)

# Allow sudo to service accunts for orgs where this user is an owner
# Do this in the background (as it will take awhile due to numerous GH API calls)
create_service_accounts &

# set the user's default environment directories
set_conda_env_paths $groups

##
## Delete jovyan user, to stop start.sh from trying to rename it to $NB_USER
##
# STEVEN comment
# userdel -f jovyan
# rm -rf /home/jovyan

##
## Ensure their directory is correctly set up with symlinks to shared resources
##
{ test -L "$H/data"   && echo "link to /home/data exists; skipping creation"; }   || { sudo -i -u "$NB_USER" ln -s /home/data   $H/data;   }
{ test -L "$H/shared" && echo "link to /home/shared exists; skipping creation"; } || { sudo -i -u "$NB_USER" ln -s /home/shared $H/shared; }


# FIXME: we should fix this in kubespawner -- just mount the directories of the groups
# the user is a member of...
MY="/my"
mkdir "$MY"
ln -s "$DATA_DIR" "$MY/data"
ln -s "$SHARED_DIR" "$MY/shared"
mkdir "$MY/groups"
for grp in $groups; do
	ln -s "$GROUP_HOMES/$grp" "$MY/groups/$grp"
done

{ test -L "$H/lincc" && echo "$H/lincc exists; skipping creation"; } || { sudo -i -u "$NB_USER" ln -s /my $H/lincc; }

##
## Spawn a daemon to create other users, based on home directory entries
##
adduserloop()
{
	#
	# A daemon that loops in the background and creates UNIX users for any new
	# entries that show up in /home
	#
	while true
	do
		HOMEDIR=/home

		for USR in $(ls $HOMEDIR); do
			USRID=$(stat -c '%u' "$HOMEDIR/$USR")
			GROUPID=$(stat -c '%g' "$HOMEDIR/$USR")
			info checking $USR

			if grep -q $GROUPID /etc/group; then
				echo "Group with $GROUPID exists. Skipping..."
			else
				echo "Group with $GROUPID does not exist. Adding..."
				groupadd -g $GROUPID $USR
			fi

			if [[ $(id -u $USRID) ]]; then
				echo "User with $USRID exists. Skipping..."
			else
				echo "User with $USRID does not exist. Adding..."
				useradd -M -s /bin/bash -u $USRID -g $GROUPID -G users $USR -s /bin/bash && cat /etc/passwd || echo "Failed to add user $USR"
			fi
		done
		echo "sleeping 60 seconds..."
		sleep 60
	done
}

adduserloop &> /dev/null &
#adduserloop &
