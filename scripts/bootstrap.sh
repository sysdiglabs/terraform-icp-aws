#!/bin/bash

ubuntu_install(){
  # attempt to retry apt-get update until cloud-init gives up the apt lock
  until apt-get update; do
    sleep 2
  done

  until apt-get install -y \
    unzip \
    python \
    python-yaml \
    thin-provisioning-tools \
    nfs-client \
    lvm2; do
    sleep 2
  done
}

crlinux_install() {
  yum install -y \
    unzip \
    PyYAML \
    device-mapper \
    libseccomp \
    libtool-ltdl \
    libcgroup \
    iptables \
    device-mapper-persistent-data \
    nfs-util \
    lvm2
}

awscli_install() {
  # already installed, exit
  which aws

  if [ $? -eq 0 ]; then
    /usr/local/bin/aws --version
    return 0
  fi

  echo "installing aws cli ..."
  cd /tmp
  rm -rf awscli-bundle*
  curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
  unzip awscli-bundle.zip
  ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
}

docker_install() {
  echo "Install docker from ${package_location}"
  sourcedir=/tmp/icp-docker

  if docker --version; then
    echo "Docker already installed. Exiting"
    return 0
  fi

  # Figure out if we're asked to install at all
  if [[ ! -z ${package_location} ]]; then
    mkdir -p ${sourcedir}

    # Decide which protocol to use
    if [[ "${package_location:0:2}" == "s3" ]]
    then
      # Figure out what we should name the file
      filename="icp-docker.bin"
      /usr/local/bin/aws s3 cp ${package_location} ${sourcedir}/${filename}
      package_file="${sourcedir}/${filename}"
    fi

    chmod a+x ${package_file}
    ${package_file} --install
  elif [[ "${OSLEVEL}" == "ubuntu" ]]; then
    # if we're on ubuntu, we can install docker-ce off of the repo
    apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

    add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) \
      stable"

    apt-get update && apt-get install -y docker-ce
  fi

  partprobe
  lsblk

  systemctl enable docker
  storage_driver=`docker info | grep 'Storage Driver:' | cut -d: -f2 | sed -e 's/\s//g'`
  echo "storage driver is ${storage_driver}"
  if [ "${storage_driver}" == "devicemapper" ]; then
    # check if loop lvm mode is enabled
    if [ -z `docker info | grep 'loop file'` ]; then
      echo "Direct-lvm mode is already configured."
      return 0
    fi

    # TODO if docker block device is not provided, make sure we use overlay2 storage driver
    if [ -z "${docker_disk}" ]; then
      echo "docker loop-lvm mode is configured and a docker block device was not specified!  This is not recommended for production!"
      return 0
    fi

    echo "A docker disk ${docker_disk} is provided, setting up direct-lvm mode ..."

    # docker installer uses devicemapper already
    cat > /tmp/daemon.json <<EOF
{
  "storage-opts": [
    "dm.directlvm_device=${docker_disk}"
  ]
}
EOF
  else
    echo "Setting up devicemapper with direct-lvm mode ..."

    cat > /tmp/daemon.json <<EOF
{
  "storage-driver": "devicemapper",
  "storage-opts": [
    "dm.directlvm_device=${docker_disk}"
  ]
}
EOF
  fi

  mv /tmp/daemon.json /etc/docker/daemon.json
  systemctl restart docker

  # docker takes a while to start because it needs to prepare the
  # direct-lvm device ... loop here until it's running
  _count=0
  systemctl is-active docker | while read line; do
    if [ ${line} == "active" ]; then
      break
    fi

    echo "Docker is not active yet; waiting 3 seconds"
    sleep 3
    _count=$((_count+1))

    if [ ${_count} -gt 10 ]; then
      echo "Docker not active after 30 seconds"
      return 1
    fi
  done

  echo "Docker is installed."
  docker info
}

image_load() {
  if [[ ! -z $(docker images -q ${image_bootstrap}) ]]; then
    # If we don't have an image locally we'll pull from docker hub registry
    echo "Not required to load images. Exiting"
    return 0
  fi

  if [[ ! -z "${image_location}" ]]; then
    # Decide which protocol to use
    if [[ "${image_location:0:2}" == "s3" ]]; then
      # stream it right out of s3 into docker
      echo "Load docker images from ${image_location} ..."
      /usr/local/bin/aws s3 cp ${image_location} - | tar zxf - -O | docker load
    fi
  fi
}


##### MAIN #####
while getopts ":p:d:i:s:" arg; do
    case "${arg}" in
      p)
        package_location=${OPTARG}
        ;;
      d)
        docker_disk=${OPTARG}
        ;;
      i)
        image_location=${OPTARG}
        ;;
      s)
        image_bootstrap=${OPTARG}
        ;;
    esac
done


#Find Linux Distro
if grep -q -i ubuntu /etc/*release
  then
    OSLEVEL=ubuntu
  else
    OSLEVEL=other
fi
echo "Operating System is $OSLEVEL"

# pre-reqs
if [ "$OSLEVEL" == "ubuntu" ]; then
  ubuntu_install
else
  crlinux_install
fi

awscli_install
docker_install
image_load

echo "Complete.."
