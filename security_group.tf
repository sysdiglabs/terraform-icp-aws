/* Default security group */
resource "aws_security_group" "default" {
  name = "icp_default_sg-${random_id.clusterid.hex}"
  description = "Default security group that allows inbound and outbound traffic from all instances in the VPC"
  vpc_id = "${aws_vpc.icp_vpc.id}"

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["${aws_vpc.icp_vpc.cidr_block}"]
    self        = true
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  tags = "${merge(
    var.default_tags,
    map("Name", "icp-default-sg-${random_id.clusterid.hex}"),
    map("kubernetes.io/cluster/${random_id.clusterid.hex}", "${random_id.clusterid.hex}")
  )}"
}

resource "aws_security_group" "workers" {
  name = "icp_workers_sg-${random_id.clusterid.hex}"
  description = "Security group for ICP worker nodes"
  vpc_id = "${aws_vpc.icp_vpc.id}"

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    self        = true
  }

  tags = "${merge(
    var.default_tags,
    map("Name", "icp-workers-sg-${random_id.clusterid.hex}")
  )}"
}

resource "aws_security_group" "management" {
  count = "${var.management["nodes"] > 0 ? 1 : 0 }"
  name = "icp_management_sg-${random_id.clusterid.hex}"
  description = "Security group for ICP management nodes"
  vpc_id = "${aws_vpc.icp_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  tags = "${merge(
    var.default_tags,
    map("Name", "icp-management-sg-${random_id.clusterid.hex}")
  )}"
}

resource "aws_security_group" "va" {
  count = "${var.va["nodes"] > 0 ? 1 : 0 }"
  name = "icp_va_sg-${random_id.clusterid.hex}"
  description = "Security group for ICP va nodes"
  vpc_id = "${aws_vpc.icp_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  tags = "${merge(
    var.default_tags,
    map("Name", "icp-va-sg-${random_id.clusterid.hex}")
  )}"
}

resource "aws_security_group_rule" "bastion-22-ingress" {
  count = "${var.bastion["nodes"] > 0 ? length(var.allowed_cidr_bastion_22) : 0}"
  type = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = [
    "${element(var.allowed_cidr_bastion_22, count.index)}"
  ]
  security_group_id = "${aws_security_group.bastion-22.id}"
}

resource "aws_security_group_rule" "bastion-22-egress" {
  count = "${var.bastion["nodes"] > 0 ? 1 : 0}"
  type = "egress"
  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = "${aws_security_group.bastion-22.id}"
}

resource "aws_security_group" "bastion-22" {
  count = "${var.bastion["nodes"] > 0 ? 1 : 0}"
  name = "icp-bastion-22-${random_id.clusterid.hex}"
  description = "allow SSH"
  vpc_id = "${aws_vpc.icp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map("Name", "icp-bastion-22-${random_id.clusterid.hex}")
  )}"
}

resource "aws_security_group_rule" "proxy-80-ngw" {
    count = "${length(var.azs)}"
    type = "ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${element(aws_eip.icp_ngw_eip.*.public_ip, count.index)}/32"]
    security_group_id = "${aws_security_group.proxy-80.id}"
    description = "allow icp to contact itself on console endpoint over the nat gateway"
}

resource "aws_security_group_rule" "proxy-80-ingress" {
  count = "${length(var.allowed_cidr_proxy_80)}"
  type = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = [
    "${element(var.allowed_cidr_proxy_80, count.index)}"
  ]
  security_group_id = "${aws_security_group.proxy-80.id}"
}

resource "aws_security_group_rule" "proxy-80-egress" {
  type = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = "${aws_security_group.proxy-80.id}"
}

resource "aws_security_group" "proxy-80" {
  name = "icp-proxy-80-${random_id.clusterid.hex}"
  description = "allow http to proxy nodes"
  vpc_id = "${aws_vpc.icp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map("Name", "icp-proxy-80-${random_id.clusterid.hex}")
  )}"
}

resource "aws_security_group_rule" "proxy-443-ngw" {
    count = "${length(var.azs)}"
    type = "ingress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${element(aws_eip.icp_ngw_eip.*.public_ip, count.index)}/32"]
    security_group_id = "${aws_security_group.proxy-443.id}"
    description = "allow icp to contact itself on console endpoint over the nat gateway"
}

resource "aws_security_group_rule" "proxy-443-ingress" {
  count = "${length(var.allowed_cidr_proxy_443)}"
  type = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = [
    "${element(var.allowed_cidr_proxy_443, count.index)}"
  ]
  security_group_id = "${aws_security_group.proxy-443.id}"
}

resource "aws_security_group_rule" "proxy-443-egress" {
  type = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = "${aws_security_group.proxy-443.id}"
}

resource "aws_security_group" "proxy-443" {
  name = "icp-proxy-443-${random_id.clusterid.hex}"
  description = "allow https to proxy nodes"
  vpc_id = "${aws_vpc.icp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map("Name", "icp-proxy-443-${random_id.clusterid.hex}")
  )}"
}

resource "aws_security_group_rule" "master-8443-ngw" {
    count = "${length(var.azs)}"
    type = "ingress"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["${element(aws_eip.icp_ngw_eip.*.public_ip, count.index)}/32"]
    security_group_id = "${aws_security_group.master-8443.id}"
    description = "allow icp to contact itself on console endpoint over the nat gateway"
}

resource "aws_security_group_rule" "master-8443-ingress" {
  count = "${length(var.allowed_cidr_master_8443)}"
  type = "ingress"
  from_port   = 8443
  to_port     = 8443
  protocol    = "tcp"
  cidr_blocks = [
    "${element(var.allowed_cidr_master_8443, count.index)}"
  ]
  security_group_id = "${aws_security_group.master-8443.id}"
}

resource "aws_security_group_rule" "master-8443-egress" {
  type = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = "${aws_security_group.master-8443.id}"
}

resource "aws_security_group" "master-8443" {
  name = "icp-master-8443-${random_id.clusterid.hex}"
  description = "allow incoming to master node console"
  vpc_id = "${aws_vpc.icp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map("Name", "icp-master-8443-${random_id.clusterid.hex}")
  )}"
}

resource "aws_security_group_rule" "master-8001-ingress" {
  count = "${length(var.allowed_cidr_master_8001)}"
  type = "ingress"
  from_port   = 8001
  to_port     = 8001
  protocol    = "tcp"
  cidr_blocks = [
    "${element(var.allowed_cidr_master_8001, count.index)}"
  ]
  security_group_id = "${aws_security_group.master-8001.id}"
}

resource "aws_security_group_rule" "master-8001-egress" {
  type = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = "${aws_security_group.master-8001.id}"
}

resource "aws_security_group_rule" "master-8001-ngw" {
    count = "${length(var.azs)}"
    type = "ingress"
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["${element(aws_eip.icp_ngw_eip.*.public_ip, count.index)}/32"]
    security_group_id = "${aws_security_group.master-8001.id}"
    description = "allow icp to contact its kubernetes API over nat gateway"
}

resource "aws_security_group" "master-8001" {
  name = "icp-master-8001-${random_id.clusterid.hex}"
  description = "allow incoming to ICP kubernetes API"
  vpc_id = "${aws_vpc.icp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map("Name", "icp-master-8001-${random_id.clusterid.hex}")
  )}"
}

resource "aws_security_group_rule" "master-8500-ingress" {
  count = "${length(var.allowed_cidr_master_8500)}"
  type = "ingress"
  from_port   = 8500
  to_port     = 8500
  protocol    = "tcp"
  cidr_blocks = [
    "${element(var.allowed_cidr_master_8500, count.index)}"
  ]
  security_group_id = "${aws_security_group.master-8500.id}"
}

resource "aws_security_group_rule" "master-8500-ngw" {
    count = "${length(var.azs)}"
    type = "ingress"
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["${element(aws_eip.icp_ngw_eip.*.public_ip, count.index)}/32"]
    security_group_id = "${aws_security_group.master-8500.id}"
    description = "allow icp to contact itself on registry endpoint over the nat gateway"
}

resource "aws_security_group_rule" "master-8500-egress" {
  type = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = "${aws_security_group.master-8500.id}"
}

resource "aws_security_group" "master-8500" {
  name = "icp-master-8500-${random_id.clusterid.hex}"
  description = "allow incoming to icp private registry"
  vpc_id = "${aws_vpc.icp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map("Name", "icp-master-8500-${random_id.clusterid.hex}")
  )}"
}

resource "aws_security_group_rule" "master-9443-ngw" {
    count = "${length(var.azs)}"
    type = "ingress"
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
    cidr_blocks = ["${element(aws_eip.icp_ngw_eip.*.public_ip, count.index)}/32"]
    security_group_id = "${aws_security_group.master-9443.id}"
    description = "allow icp to contact itself on oidc endpoint over the nat gateway"
}

resource "aws_security_group" "master-9443" {
  name = "icp-master-9443-${random_id.clusterid.hex}"
  description = "allow incoming to icp auth service"
  vpc_id = "${aws_vpc.icp_vpc.id}"

  tags = "${merge(
    var.default_tags,
    map("Name", "icp-master-9443-${random_id.clusterid.hex}")
  )}"
}


resource "aws_security_group" "icp-registry-mount" {
  count = "${var.master["nodes"] > 1 ? 1 : 0 }"
  name = "icp_efs_registry_sg-${random_id.clusterid.hex}"
  description = "allow incoming to EFS from master nodes"
  vpc_id = "${aws_vpc.icp_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [ "${aws_security_group.default.id}"]
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [ "${aws_security_group.default.id}"]
    self        = true
  }

  tags = "${merge(
    var.default_tags,
    map("Name", "icp-registry-mount-sg-${random_id.clusterid.hex}")
  )}"
}

resource "aws_security_group" "icp-audit-mount" {
  count = "${var.master["nodes"] > 1 ? 1 : 0 }"
  name = "icp_efs_audit_sg-${random_id.clusterid.hex}"
  description = "allow incoming to EFS from master nodes"
  vpc_id = "${aws_vpc.icp_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [
      "${aws_security_group.default.id}"
    ]
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [
      "${aws_security_group.default.id}"
    ]
    self        = true
  }

  tags = "${merge(
    var.default_tags,
    map("Name", "icp-audit-mount-sg-${random_id.clusterid.hex}")
  )}"
}
