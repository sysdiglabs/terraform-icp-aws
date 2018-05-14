var aws = require('aws-sdk');
var kubeapi = require('kubernetes-client');
var fs = require('fs');

aws.config.update({region: region});
aws.config.setPromisesDependency(Promise);

function get_instance_ip(region, instance_id) {
  var ec2 = new aws.EC2({apiVersion: '2016-11-15'});

  console.log("InstanceID: " + instance_id);

  var params = {
    DryRun: false,
    InstanceIds: [ instance_id ],
  };

  return ec2.describeInstances(params, function(err, result) {
    if (err) {
      console.log(err, err.stack);
      throw err;
    } else {
      console.log("Instance IP address is: " + result.Reservations[0].Instances[0].PrivateIpAddress);
      return result.Reservations[0].Instances[0].PrivateIpAddress;
    }
  });
}

function get_bucket_object(bucketName, key) {
  var s3 = new aws.S3({apiVersion: '2006-03-01'});

  var params = {
    Bucket: bucketName,
    Key: key
  };

  s3.getObject(params, function(err, data) {
    if (err) {
      console.log(err, err.stack);
      throw err;
    } else {
      console.log(data);           // successful response

      return data.Body;
    }
  });
}

function create_job(ca_crt, client_cert, client_key, job) {
  var batch = new kubeapi.Batch({
    url: process.env.kube_api_url,
    namespace: process.env.kube_namespace || 'default', // Defaults to 'default'
    ca: ca_crt,
    cert: client_cert,
    key: client_key,
    promises: true
  });

  return batch.namespaces(process.env.kube_namespace).jobs.post({body: job}).then(function(result) {
    console.log("submitted job");
  });
}

function fail_autoscaling(params) {
  const autoscaling = new aws.AutoScaling({apiVersion: '2011-01-01'});

  var autoscaling_params = params.detail;
  autoscaling_params.LifecycleActionResult = 'ABANDON';

  delete autoscaling_params.EC2InstanceId;
  delete autoscaling_params.LifecycleTransition;
  delete autoscaling_params.NotificationMetadata;

  console.log("Sending autoscaling lifecycle params: " + JSON.stringify(autoscaling_params, null, 2));

  return autoscaling.completeLifecycleAction(autoscaling_params).promise()
    .then(function(result) {
        console.log("competed lifecycle action");
    });
};

module.exports.get_instance_ip = get_instance_ip;
module.exports.create_job = create_job;
module.exports.fail_autoscaling = fail_autoscaling;
