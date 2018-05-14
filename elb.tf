
resource "aws_lb_target_group" "icp-console-8443" {
  name = "icp-${random_id.clusterid.hex}-master-8443-tg"
  port = 8443
  protocol = "TCP"
  tags = "${var.default_tags}"
  vpc_id = "${aws_vpc.icp_vpc.id}"
}

resource "aws_lb_target_group" "icp-console-9443" {
  name = "icp-${random_id.clusterid.hex}-master-9443-tg"
  port = 9443
  protocol = "TCP"
  tags = "${var.default_tags}"
  vpc_id = "${aws_vpc.icp_vpc.id}"
}

resource "aws_lb_target_group" "icp-kubernetes-api-8001" {
  name = "icp-${random_id.clusterid.hex}-master-8001-tg"
  port = 8001
  protocol = "TCP"
  tags = "${var.default_tags}"
  vpc_id = "${aws_vpc.icp_vpc.id}"
}

resource "aws_lb_target_group" "icp-registry-8500" {
  name = "icp-${random_id.clusterid.hex}-master-8500-tg"
  port = 8500
  protocol = "TCP"
  tags = "${var.default_tags}"
  vpc_id = "${aws_vpc.icp_vpc.id}"
}

resource "aws_lb_listener" "icp-console-8443" {
  load_balancer_arn = "${aws_lb.icp-console.arn}"
  port = "8443"
  protocol = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.icp-console-8443.arn}"
    type = "forward"
  }
}

resource "aws_lb_listener" "icp-console-9443" {
  load_balancer_arn = "${aws_lb.icp-console.arn}"
  port = "9443"
  protocol = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.icp-console-9443.arn}"
    type = "forward"
  }
}


resource "aws_lb_listener" "icp-registry-8500" {
  load_balancer_arn = "${aws_lb.icp-console.arn}"
  port = "8500"
  protocol = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.icp-registry-8500.arn}"
    type = "forward"
  }
}

resource "aws_lb_listener" "icp-kubernetes-api-8001" {
  load_balancer_arn = "${aws_lb.icp-console.arn}"
  port = "8001"
  protocol = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.icp-kubernetes-api-8001.arn}"
    type = "forward"
  }
}


resource "aws_lb_target_group_attachment" "master-8443" {
  count = "${var.master["nodes"]}"
  target_group_arn = "${aws_lb_target_group.icp-console-8443.arn}"
  target_id = "${element(aws_instance.icpmaster.*.id, count.index)}"
  port = 8443

}

resource "aws_lb_target_group_attachment" "master-9443" {
  count = "${var.master["nodes"]}"
  target_group_arn = "${aws_lb_target_group.icp-console-9443.arn}"
  target_id = "${element(aws_instance.icpmaster.*.id, count.index)}"
  port = 9443
}

resource "aws_lb_target_group_attachment" "master-8001" {
  count = "${var.master["nodes"]}"
  target_group_arn = "${aws_lb_target_group.icp-kubernetes-api-8001.arn}"
  target_id = "${element(aws_instance.icpmaster.*.id, count.index)}"
  port = 8001

}

resource "aws_lb_target_group_attachment" "master-8500" {
  count = "${var.master["nodes"]}"
  target_group_arn = "${aws_lb_target_group.icp-registry-8500.arn}"
  target_id = "${element(aws_instance.icpmaster.*.id, count.index)}"
  port = 8500

}

resource "aws_lb" "icp-console" {
  name = "icp-console"
  load_balancer_type = "network"
#  internal = "true"

  tags = "${var.default_tags}"

  # The same availability zone as our instance
  subnets = [ "${aws_subnet.icp_public_subnet.*.id}" ]
}

resource "aws_lb_target_group" "icp-proxy-443" {
  name = "icp-${random_id.clusterid.hex}-proxy-443-tg"
  port = 443
  protocol = "TCP"
  tags = "${var.default_tags}"
  vpc_id = "${aws_vpc.icp_vpc.id}"
}

resource "aws_lb_target_group" "icp-proxy-80" {
  name = "icp-${random_id.clusterid.hex}-proxy-80-tg"
  port = 80
  protocol = "TCP"
  tags = "${var.default_tags}"
  vpc_id = "${aws_vpc.icp_vpc.id}"
}

resource "aws_lb_target_group_attachment" "icp-proxy-443" {
  count = "${var.proxy["nodes"]}"
  target_group_arn = "${aws_lb_target_group.icp-proxy-443.arn}"
  target_id = "${element(aws_instance.icpproxy.*.id, count.index)}"
  port = 443

}

resource "aws_lb_target_group_attachment" "icp-proxy-80" {
  count = "${var.proxy["nodes"]}"
  target_group_arn = "${aws_lb_target_group.icp-proxy-80.arn}"
  target_id = "${element(aws_instance.icpproxy.*.id, count.index)}"
  port = 80

}

resource "aws_lb_listener" "icp-proxy-443" {
  load_balancer_arn = "${aws_lb.icp-proxy.arn}"
  port = "443"
  protocol = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.icp-proxy-443.arn}"
    type = "forward"
  }
}
resource "aws_lb_listener" "icp-proxy-80" {
  load_balancer_arn = "${aws_lb.icp-proxy.arn}"
  port = "80"
  protocol = "TCP"
  default_action {
    target_group_arn = "${aws_lb_target_group.icp-proxy-80.arn}"
    type = "forward"
  }
}

resource "aws_lb" "icp-proxy" {
  name = "icp-proxy"
  load_balancer_type = "network"

  # The same availability zone as our instance
  subnets = [ "${aws_subnet.icp_public_subnet.*.id}" ]

  tags = "${var.default_tags}"
}
