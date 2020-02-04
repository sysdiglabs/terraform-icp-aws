#!/bin/sh

#We need to run an older version of terraform inside a docker container
docker run --rm -it -v ${HOME}/sd/service-account.json:/home/terraform/service-account.json:ro -v ${HOME}/.aws:/home/terraform/.aws -v $(PWD):/home/terraform/host sysdiglabs/terraform-ibm-iks $*
