#!/bin/bash

source /tmp/icp_scripts/functions.sh

while getopts ":b:i:" arg; do
    case "${arg}" in
      b)
        s3_lambda_bucket=${OPTARG}
        ;;
      i)
        inception_image=${OPTARG}
        ;;
    esac
done

parse_icpversion ${inception_image}
echo "registry=${registry:-not specified} org=$org repo=$repo tag=$tag"

sudo docker run \
  -e LICENSE=accept \
  --net=host \
  -v /usr/local/bin:/data \
  ${registry}${registry:+/}${org}/${repo}:${tag} \
  cp /usr/local/bin/kubectl /data

/usr/local/bin/kubectl -s localhost:8888 create clusterrolebinding lambda-role --clusterrole=cluster-admin --user=lambda --group=lambda
openssl genrsa -out /tmp/lambda-key.pem 4096
openssl req -new -key /tmp/lambda-key.pem -out /tmp/lambda-cert.csr -subj '/O=lambda/CN=lambda'
openssl x509 -req -days 3650 -sha256 -in /tmp/lambda-cert.csr -CA /etc/cfc/conf/ca.crt -CAkey /etc/cfc/conf/ca.key -set_serial 2 -out /tmp/lambda-cert.pem

/usr/local/bin/aws s3 cp /tmp/lambda-cert.pem s3://${s3_lambda_bucket}/lambda-cert.pem
/usr/local/bin/aws s3 cp /tmp/lambda-key.pem s3://${s3_lambda_bucket}/lambda-key.pem
/usr/local/bin/aws s3 cp /etc/cfc/conf/ca.crt s3://${s3_lambda_bucket}/ca.crt
