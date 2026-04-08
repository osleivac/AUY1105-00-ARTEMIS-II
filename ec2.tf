# ─────────────────────────────────────────────────────────────
# ec2.tf  –  Configuración ARTEMIS-II
# ─────────────────────────────────────────────────────────────

variable "public_key" {
  description = "Clave pública SSH inyectada por Pipeline"
  type        = string
  sensitive   = true
}

variable "mi_ip_publica" {
  description = "IP pública para restringir el acceso SSH"
  type        = string
  default     = "181.43.52.214/32" 
}

data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "AUY1105-ARTEMIS-II-key" {
  key_name   = "AUY1105-ARTEMIS-II-key"
  public_key = var.public_key
}

resource "aws_security_group" "AUY1105-ARTEMIS-II-sg" {
  name        = "AUY1105-ARTEMIS-II-sg"
  description = "Security Group restringido a SSH"
  vpc_id      = aws_vpc.AUY1105-ARTEMIS-II-vpc.id

  ingress {
    description = "SSH desde IP Especifica"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.mi_ip_publica]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "AUY1105-ARTEMIS-II-sg" }
}

resource "aws_instance" "AUY1105-ARTEMIS-II-ec2" {
  ami                         = data.aws_ami.ubuntu_24_04.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.AUY1105-ARTEMIS-II-subnet-pub-1.id
  vpc_security_group_ids      = [aws_security_group.AUY1105-ARTEMIS-II-sg.id]
  key_name                    = aws_key_pair.AUY1105-ARTEMIS-II-key.key_name
  associate_public_ip_address = true

  user_data = filebase64("${path.module}/install.sh")

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  tags = { Name = "AUY1105-ARTEMIS-II-ec2" }
}