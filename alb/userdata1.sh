#!/bin/bash

# Update the package list
sudo apt-get update

# Install Apache2
sudo apt-get install -y apache2

# Get the instance ID using the instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Install the AWS CLI
sudo apt-get install -y awscli

# Download the image from the S3 bucket
# aws s3 cp s3://myterraformprojectbucket2023/project.webp /var/www/html/project.png --acl public-read

# Create a simple HTML file with the portfolio content and display the images
sudo cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>Terraform Project</title>
  <style>
    /* Add animation and styling for the text */
    @keyframes colorChange {
      0% { color: red; }
      50% { color: green; }
      100% { color: blue; }
    }
    h1 {
      animation: colorChange 2s infinite;
    }
  </style>
</head>
<body>
  <h1>Terraform Project Server 2</h1>
  <p>ABD2</p>
</body>
</html>
EOF

# Start Apache and enable it to start on boot
sudo systemctl start apache2
sudo systemctl enable apache2
