resource "aws_iam_role" "sonarqube" {
  name = "task-manager-sonarqube"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "sonarqube_ssm" {
  name = "ssm-write"
  role = aws_iam_role.sonarqube.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:PutParameter", "ssm:GetParameter"]
      Resource = "arn:aws:ssm:*:*:parameter/task-manager/sonarqube-*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sonarqube_ssm_core" {
  role       = aws_iam_role.sonarqube.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "sonarqube" {
  name = "task-manager-sonarqube"
  role = aws_iam_role.sonarqube.name
}

resource "aws_security_group" "sonarqube" {
  name        = "task-manager-sonarqube-sg"
  description = "SonarQube server"
  vpc_id      = aws_vpc.sonarqube.id

  ingress {
    description = "SonarQube UI"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "sonarqube" {
  domain = "vpc"

  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_eip_association" "sonarqube" {
  instance_id   = aws_instance.sonarqube.id
  allocation_id = aws_eip.sonarqube.id
}

resource "aws_instance" "sonarqube" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.large"
  subnet_id                   = aws_subnet.sonarqube.id
  vpc_security_group_ids      = [aws_security_group.sonarqube.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.sonarqube.name

  user_data = <<-EOF
    #!/bin/bash

    sysctl -w vm.max_map_count=524288
    sysctl -w fs.file-max=131072
    echo "vm.max_map_count=524288" >> /etc/sysctl.conf
    echo "fs.file-max=131072" >> /etc/sysctl.conf

    dnf update -y
    dnf install -y docker jq
    systemctl start docker
    systemctl enable docker

    mkdir -p /opt/sonarqube/{data,logs,extensions}
    chown -R 1000:1000 /opt/sonarqube

    docker run -d \
      --name sonarqube \
      --restart always \
      -p 9000:9000 \
      -e SONAR_WEB_JAVAOPTS="-Xmx512m -Xms128m" \
      -e SONAR_CE_JAVAOPTS="-Xmx512m -Xms128m" \
      -e SONAR_SEARCH_JAVAOPTS="-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m" \
      -v /opt/sonarqube/data:/opt/sonarqube/data \
      -v /opt/sonarqube/logs:/opt/sonarqube/logs \
      -v /opt/sonarqube/extensions:/opt/sonarqube/extensions \
      sonarqube:community

    echo "Waiting for SonarQube to start (up to 30 min)..."
    for i in $(seq 1 120); do
      STATUS=$(curl -s http://localhost:9000/api/system/status | jq -r '.status' 2>/dev/null || echo "")
      echo "Attempt $i/120: status=$STATUS"
      [ "$STATUS" = "UP" ] && break
      sleep 15
    done

    if [ "$STATUS" != "UP" ]; then
      echo "SonarQube failed to start after 30 minutes"
      docker logs sonarqube --tail 100
      exit 1
    fi

    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
    SONAR_URL="http://${aws_eip.sonarqube.public_ip}:9000"

    ADMIN_PASS="Sonar@$(openssl rand -hex 12)"
    curl -s -u admin:admin -X POST "$SONAR_URL/api/users/change_password" \
      -d "login=admin&previousPassword=admin&password=$ADMIN_PASS"

    aws ssm put-parameter \
      --region "$REGION" \
      --name "/task-manager/sonarqube-admin-password" \
      --value "$ADMIN_PASS" \
      --type "SecureString" \
      --overwrite

    for PROJECT in task-manager-backend task-manager-frontend; do
      curl -s -u admin:$ADMIN_PASS -X POST "$SONAR_URL/api/projects/create" \
        -d "name=$PROJECT&project=$PROJECT"
    done

    TOKEN=$(curl -s -u admin:$ADMIN_PASS -X POST "$SONAR_URL/api/user_tokens/generate" \
      -d "name=ci-token&type=GLOBAL_ANALYSIS_TOKEN" | jq -r '.token')

    aws ssm put-parameter \
      --region "$REGION" \
      --name "/task-manager/sonarqube-token" \
      --value "$TOKEN" \
      --type "SecureString" \
      --overwrite

    aws ssm put-parameter \
      --region "$REGION" \
      --name "/task-manager/sonarqube-url" \
      --value "$SONAR_URL" \
      --type "String" \
      --overwrite

    echo "SonarQube setup complete: $SONAR_URL"
  EOF

  lifecycle {
    # prevent_destroy = true
    ignore_changes  = [user_data]
  }

  tags = {
    Name = "task-manager-sonarqube"
  }
}

output "sonarqube_url" {
  value = "http://${aws_eip.sonarqube.public_ip}:9000"
}
