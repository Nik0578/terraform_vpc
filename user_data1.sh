#!/bin/bash
apt update
apt install -y apache2

# Get the instance ID using the instance metadata
sleep 10  # Ensure the instance is fully initialized
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo "Failed to retrieve metadata")
echo "Instance ID: $INSTANCE_ID" > /var/log/user-data.log
# Install the AWS CLI
apt install -y awscli

# Download the images from S3 bucket
#aws s3 cp s3://myterraformprojectbucket2023/project.webp /var/www/html/project.png --acl public-read

# Create a simple HTML file with the portfolio content and display the images
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>My Portfolio</title>
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
  <h1>Welcome to new App server</h1>
  <h2>Instance ID: <span style="color:green">$INSTANCE_ID</span></h2>
  <p>Welcome to Nikhil Kumar Mishra</p>
  
</body>
</html>
EOF

# Start Apache and enable it on boot
systemctl start apache2
systemctl enable apache2