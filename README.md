## Bedrock on Docker 🐋

Dockerified Bedrock setup helped out by docker-sync

## Prerequisites

For this set-up to function, you will need these things installed:

- Docker
- docker-sync
- unison, only if using with docker-sync (`brew install unison`)
- Node.js with jspm and yarn installed globally

## Setting up

First of all, change the project settings in `Makefile` top variables from 'bedrock' to your chosen project name (this HAS to be unique for docker-sync to function properly).
By default, the repo comes with production and development stages. To start developing, you don't need to amend anything, but you can look into ./.docker/stages/env files and change accoring to your needs.

## Running

To set up the project, run

```
make setup
```

This will:

- Create all the needed docker-compose and docker-sync files, and self-signed certificates
- Download templates
- Build the bedrock image
  Then, tun:

```
make dev
```

This will update and build the templates, and then launch docker-sync.
If everything is set-up properly, you can open https://docker.test (map it to localhost in you hostfile, if you haven't changed it to something else in the env files).

# Deploy

We only use flightplan now so to deploy do:

`make deploy` which will default to staging
`make deploy TO=production` which will send to production.

You no longer need to specifically type `DEPLOY_WITH=flightplan`
