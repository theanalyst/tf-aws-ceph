provider "aws" {
}

resource "aws_vpc" "main" {
  cidr_block = "${var.vpn_cidr}"
  tags {
    Name = "terraform-vpc"
  }
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "terraform-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.public_subnet_cidr}"
  tags {
    Name = "terraform-public-subnet"
  }
  depends_on = ["aws_internet_gateway.default"]
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "default_vpc" {
  name = "all-vpc-traffic"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    self = true
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    self = true
  }
}

resource "aws_security_group" "http_proxy" {
  name = "ssh"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "internet" {
  name = "internet"
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "salt-master" {
  ami = "${var.nat_ami}"
  instance_type = "t2.small"
  tags {
    Name = "terraform-test"
  }
  subnet_id = "${aws_subnet.public.id}"
  vpc_security_group_ids = ["${aws_security_group.default_vpc.id}", "${aws_security_group.http_proxy.id}"]
  key_name = "abhishekl"
  depends_on = ["aws_internet_gateway.default"]
  tags = {
    Name = "salt-master"
  }
  source_dest_check = false
}

output "master-ip" {
  value = "${join(" ", aws_instance.salt-master.*.public_ip)}"
}

output "master-dns" {
  value = "${join(" ", aws_instance.salt-master.*.public_dns)}"
}

resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.private_subnet_cidr}"
  map_public_ip_on_launch = false
  depends_on = ["aws_instance.salt-master"]
  tags {
    Name = "tf-private"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.salt-master.id}"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_instance" "ceph-mon" {
  count = "${var.ceph_mon_count}"
  ami = "${var.nat_ami}"
  instance_type = "t2.small"
  subnet_id = "${aws_subnet.private.id}"
  security_groups = ["${aws_security_group.default_vpc.id}"]
  source_dest_check = false
  tags = {
    Name = "ceph-mon-{count.index}"
  }
  key_name = "${var.key_name}"
}

output "mon_ip" {
  value = "${join(",", aws_instance.ceph-mon.*.private_ip)}"
}
