resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}


#you need to map public ip on launch , so for that we use mao ip
#we need to create two subnet in two diff regions where we have to launch ec2
#then you need to create internet gateway
#then need to create route table(route table will define where your traffic should go to or how traffic will flow to subnet)
resource "aws_subnet" "mysubnet" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "mysubnet2" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
}


#we have to define inside which vpc we are launchig this internet gateway.
resource "aws_internet_gateway" "igway" {
  vpc_id = aws_vpc.myvpc.id
}

#we have to create route table so that we can attach to our public subnet of our own created vpc
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route{
    cidr_block = "0.0.0.0/0"   #you will see in console for help 
    gateway_id = aws_internet_gateway.igway.id 
  }
}

#here we need to pass 2 params ONE in which subnet we want to aattach SECOND what is route table id
resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.mysubnet.id
    route_table_id = aws_route_table.RT.id
  
}

resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.mysubnet2.id
    route_table_id = aws_route_table.RT.id
  
}


#Now we have to create security group and open ports as per need outbound and inbounds
resource "aws_security_group" "mysg" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "for web access"
    protocol  = "tcp"
    self      = true
    from_port = 80
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "for ssh to server"
    protocol  = "tcp"
    self      = true
    from_port = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   =0
    to_port     =0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "appserver1" {
    ami = "ami-0dee22c13ea7a9a67"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.mysg.id ]
    subnet_id = aws_subnet.mysubnet.id
    user_data = file("user_data.sh")
}

resource "aws_instance" "appserver2" {
    ami = "ami-0dee22c13ea7a9a67"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.mysg.id ]
    subnet_id = aws_subnet.mysubnet2.id
    user_data = file("user_data1.sh")
}

#create LB

resource "aws_lb" "my_alb" {
    name = "myalb"
    internal = false
    load_balancer_type = "application"

    security_groups = [ aws_security_group.mysg.id ]
    subnets = [ aws_subnet.mysubnet.id, aws_subnet.mysubnet2.id ]

}


#create tg

resource "aws_lb_target_group" "tg" {
    name = "my-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.myvpc.id

    health_check {
      path = "/"
      port = 80
    }
  
}

locals {
  instances = {
    appserver1 = aws_instance.appserver1.id
    appserver2 = aws_instance.appserver2.id
  }
}

resource "aws_lb_target_group_attachment" "attach" {
  for_each        = local.instances
  target_group_arn = aws_lb_target_group.tg.arn
  target_id       = each.value
  port            = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type = "forward"
    
  }
}
