## You must set a key file name to be able to ssh to any of the created VMs
# key_name = "<name of your ssh key>"

image_location = "s3://icp-docker-tarball/ibm-cloud-private-x86_64-3.2.0.tar.gz"

ami = "rhel"         # Use RHEL and supply docker package
docker_package_location = "s3://icp-docker-binaries/icp-docker-18.03.1_x86_64.bin"

icp_inception_image = "ibmcom/icp-inception-amd64:3.2.0-ee"

# We add the bastion host so we can monitor the progress
# during ICP Installation
bastion = {
 nodes = "1"
}
