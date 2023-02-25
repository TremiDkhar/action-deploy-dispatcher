#!/bin/bash

# Global Variables.
sync_command='rsync';

# Function to build the sync command.
function build_sync_command() {

	# Exit if the remote user is not set.
	if [ -z "$REMOTE_USER" ]; then
		echo "REMOTE_USER is not set. Exiting."
		exit 1
	fi

	# Exit if the remote host is not set.
	if [ -z "$REMOTE_HOST" ]; then
		echo "REMOTE_HOST is not set. Exiting."
		exit 1
	fi

	# Exit if the remote path is not set.
	if [ -z "$REMOTE_PATH" ]; then
		echo "REMOTE_PATH is not set. Exiting."
		exit 1
	fi

	# Exit if the rsync switches is not set.
	if [ -z "$INPUT_RSYNC_SWITCHES" ]; then
		echo "RSYNC_SWITCHES is not set. Exiting."
		exit 1
	fi

	sync_command="${sync_command} $INPUT_RSYNC_SWITCHES ./ $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH"

	# If .deployignore exists, add it to the sync command
	if [ -f .deployignore ]; then
		sync_command="${sync_command} --exclude-from=.deployignore"
	fi

	# Ignore everything in the .gitingore file. With proper .gitignore file, it will ignore all the files (especially to not delete) that are there on the remote server.
	sync_command="${sync_command} --exclude-from=.gitignore"

}

# Setup SSH agent
function setup_ssh_agent() {

	# Add sshpass if the SSH Passphrase is set.
	if [ -n "$SSH_LOGIN_PASSWORD" ]; then
		export SSHPASS=$SSH_LOGIN_PASSWORD # The SSHPASS environment variable is used by sshpass.
		sync_command="sshpass -e ${sync_command}"
	fi

	# Check if SSH agent is running.
	if [ -z "$SSH_AUTH_SOCK" ]; then

		echo "SSH agent is not running. Starting SSH agent..."

		# Start SSH agent.
		eval `ssh-agent -s` > /dev/null

	fi

	# Add the private key to the SSH agent
	if [ -n "$SSH_PRIVATE_KEY" ]; then

		# Export $SSH_PRIVATE_KEY_PASSWORD if it exists.
		if [ -n "$SSH_PRIVATE_KEY_PASSWORD" ]; then

			export SSHPASS=$SSH_PRIVATE_KEY_PASSWORD # The SSHPASS environment variable is used by sshpass.

			echo "Adding SSH key to SSH agent using the Private Key Password"
			sshpass -P pass -e ssh-add /dev/stdin <<<$SSH_PRIVATE_KEY

		else

			echo "Adding SSH key to SSH agent without the Private Key Password"
			ssh-add /dev/stdin <<<$SSH_PRIVATE_KEY

		fi
	fi

	echo "Create the .ssh directory if it doesn't exist"
	mkdir -p ~/.ssh

	echo "Scan for keys and add to ~/.ssh/known_hosts"
	ssh-keyscan -t rsa,dsa -H $REMOTE_HOST >> ~/.ssh/known_hosts
}

# Performing housekeeping
function perform_housekeeping() {

	echo "Performing housekeeping..."
	ssh-add -D

	echo "Killing SSH agent..."
	eval "$(ssh-agent -k)"

}

# Run the sync command.
function run_sync_command() {

	echo "Running sync command..."
	$sync_command

}

# Setup requirements
function setup_requirements() {

	# Exit if SSH Login Password or SSH Private Key Password is not set.
	if [ -z "$SSH_LOGIN_PASSWORD" ] && [ -z "$SSH_PRIVATE_KEY_PASSWORD" ]; then
		echo "SSH_LOGIN_PASSWORD or SSH_PRIVATE_KEY_PASSWORD is not set. Exiting."
		exit 1
	fi

	# List of required packages
	required_packages=("rsync" "sshpass")

	# Hold the list of missing packages
	missing_packages=''

	for package in "${required_packages[@]}"; do

		# Check if the package is installed
		if ! [ -x "$(command -v $package)" ]; then

			# Add the package to the list of missing packages
			missing_packages="$missing_packages $package"

			# Output the missing package
			echo "$package is not installed."

		fi

	done

	# If there are missing packages, install them
	if [ -n "$missing_packages" ]; then

		echo "The following packages are missing: $missing_packages"
		echo "Trying to install them..."

		apt update
		apt install $missing_packages -y

		# Reset the missing packages variable
		missing_packages=''

	fi

	# Exit if the missing packages are still not installed
	for package in "${required_packages[@]}"; do

		# Recheck if the package is installed
		if ! [ -x "$(command -v $package)" ]; then

			# Add the package to the list of missing packages
			missing_packages="$missing_packages $package"

			# Output the missing package
			echo "ERROR: $package is not installed."

		fi

	done

	# If there are still missing packages, exit
	if [ -n "$missing_packages" ]; then

		echo "Cannot install the following packages: $missing_packages"
		echo "Exiting."
		exit 1

	fi

}

# The main function
function main() {

	# Setup all the required packages
	setup_requirements

	# Setup SSH agent
	setup_ssh_agent

	# Build the sync command
	build_sync_command

	# Run the sync command
	run_sync_command

	# Perform housekeeping
	perform_housekeeping
}

main
