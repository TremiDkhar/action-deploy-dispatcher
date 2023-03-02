# GitHub Action to Deploy Code

GitHub Action for deploying code to server via rsync

## Input Variables

- `remote_user` - The ssh username.
- `remote_host` - The ssh host.
- `remote_path` - The absolute path to deployed the code.
- `ssh_login_password` - The SSH Login Password
- `ssh_private_key` - The SSH private key
- `rsync_switches` - The switches that is passes to the rsync command. Default: `-az --chown=www-data:www-data --progress`

## Sample Usage

```yaml
name: "File Deployer"
run-name: ${{ github.actor }} is deploying files to the server.
on:
  push:
    branches:
      - trunk
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Deploy Dispatcher
        uses: TremiDkhar/action-deploy-dispatcher@v0.1.2
        with:
          remote_user: ${{ secrets.REMOTE_USER }}
          remote_host: ${{ secrets.REMOTE_HOST }}
          remote_path: ${{ secrets.REMOTE_PATH }}
          ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
          ssh_private_key_password: ${{ secrets.SSH_PRIVATE_KEY_PASSWORD }}
          rsync_switches: '-azh --chown=www-data:www-data --progress'
```
