# GitHub Action to Deploy Code

GitHub Action for deploying code to server via rsync

## Input Variables

- `remote_user` - The ssh username.
- `remote_host` - The ssh host.
- `remote_path` - The absolute path to deployed the code.
- `ssh_login_password` - The SSH Login Password
- `ssh_private_key` - The SSH private key
- `rsync_switches` - The switches that is passes to the rsync command. Default: `-az --chown=www-data:www-data --progress`
