aws_region = "eu-west-1"
azs = ["a"]
key_name = "marketing-infra"

bastion = {
 nodes = "1"
}

#We need to set only one node, as we have only one AZ, or EFS mount points will fail
master = {
    nodes = "1"
    type = "m5.2xlarge"
}

#Also, need to set 1 node for proxy, management and va to disable HA which is not supported in CE edition
proxy = {
    nodes = "0"
}

management = {
    nodes = "0" #The services will run on master
}

va = {
    nodes = "0"
}

worker = {
    type = "m5.xlarge"
}

#Use inception image for CE edition
#icp_inception_image = "ibmcom/icp-inception-amd64:3.1.2"
icp_inception_image = "ibmcom/icp-inception:3.2.1"

#Use this one as fixed version to avoid new versions making changes in the plan
ami = "ami-0987ee37af7792903"
