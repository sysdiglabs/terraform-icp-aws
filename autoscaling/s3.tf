resource "aws_s3_bucket_object" "icp_lambda_function" {
  count   = "${var.enabled ? 1 : 0}"
  bucket  = "${var.lambda_s3_bucket}"
  key     = "icp-autoscale.zip"
  source  = "${data.archive_file.lambda_function.output_path}"

}
