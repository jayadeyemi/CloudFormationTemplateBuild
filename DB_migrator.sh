#!/bin/bash -xe
############################################################################################################
# ---------------------------------------------------------------------------------------------------------#
############################################################################################################
# This script is used to migrate data from Phase 1 EC2 instance to RDS instance
# Pre-requisites:
# Create a Bucket in S3 and upload Phases 1, 2, and 3 scripts.
# Manually create a key pair for EC2 instances in the public subnet.
# Save the key pair details for the public EC2 instances
# Transfer the details to Secrets Manager as detailed below:
    # Secret Name: RSA_KEYS
    # Secret Key: PUBLIC
    # Secret Value: Details of the key pair
    # Secret Key: PRIVATE
    # Secret Value: Details of the key pair

# Open CloudFormation on the AWS Management Console
# Choose Create Stack
# Input the URL for Phase 1 script
# Create your stack with your required details
# Allow for CloudFormation to complete the stack creation
# Once the stack is creation is complete, open the Public IP of the EC2 instance with its Inbuilt MySQL database
# Input your data into the Database
# Run this file to migrate the data from the EC2 instance to the RDS instance
############################################################################################################
# ---------------------------------------------------------------------------------------------------------#
############################################################################################################
# ----------------------------------------------------------
# 1) Retrieve EC2V1 Private IP
# ----------------------------------------------------------

EC2V1PrivateIP=$(aws ec2 describe-instances \
    --filters "Name=tag:Phase,Values=1" \
    --query "Reservations[*].Instances[*].PrivateIpAddress" \
    --output text)

# ----------------------------------------------------------
# 2) Retrieve RDS Credentials from Secrets Manager
# ----------------------------------------------------------
SECRET_USERNAME=$(aws secretsmanager get-secret-value --secret-id "Mydbsecret" --query 'SecretString' --output text | jq -r '.user')
SECRET_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "Mydbsecret" --query 'SecretString' --output text | jq -r '.password')
RDS_ENDPOINT=$(aws secretsmanager get-secret-value --secret-id "Mydbsecret" --query 'SecretString' --output text | jq -r '.host')
RDS_DB_NAME=$(aws secretsmanager get-secret-value --secret-id "Mydbsecret" --query 'SecretString' --output text | jq -r '.db')

# ----------------------------------------------------------
# 3) Retrieve SSH Key from Secrets Manager save as read only
# ----------------------------------------------------------
aws secretsmanager get-secret-value --secret-id RSA_KEYS \
    --query 'SecretString' --output text | jq -r '.PUBLIC' | sed 's/----- /-----\n/g; s/ -----/\n-----/g'> ec2v1_key.pem
chmod 400 ec2v1_key.pem

# ----------------------------------------------------------
# 4) Verify Retrieved Data for User
# ----------------------------------------------------------
echo "RDS Username: $SECRET_USERNAME"
echo "RDS Password: $SECRET_PASSWORD"
echo "EC2V1 Private IP: $EC2V1PrivateIP"
echo "RDS Endpoint: $RDS_ENDPOINT"
echo "RDS Database: $RDS_DB_NAME"
echo "SSH Key saved to ec2v1_key.pem"

# ----------------------------------------------------------
# 5) Migration Process: EC2V1 -> Cloud9/CloudShell/Ephemeral EC2 Instance -> RDS
# ----------------------------------------------------------

echo "############################################################################################################"
echo "#--------------------------------------Creating MySQL dump on EC2V1----------------------------------------#"
echo "############################################################################################################"
ssh -o "StrictHostKeyChecking=no" \
    -i ec2v1_key.pem \
    ubuntu@$EC2V1PrivateIP \
    "mysqldump -h localhost -u nodeapp -pstudent12 --databases STUDENTS > /tmp/data.sql"

echo "############################################################################################################"
echo "#---------------------------------------Copying data.sql to Cloud9-----------------------------------------#"
echo "############################################################################################################"
scp -o "StrictHostKeyChecking=no" \
    -i ec2v1_key.pem \
    ubuntu@$EC2V1PrivateIP:/tmp/data.sql data.sql

echo "############################################################################################################"
echo "#-------------------------------------IMPORTING MySQL DUMP INTO RDS----------------------------------------#"
echo "############################################################################################################"
mysql -h $RDS_ENDPOINT -u $SECRET_USERNAME -p$SECRET_PASSWORD -e "CREATE DATABASE STUDENTS;"
mysql -h $RDS_ENDPOINT -u $SECRET_USERNAME -p$SECRET_PASSWORD $RDS_DB_NAME < data.sql

echo "############################################################################################################"
echo "#-------------------------------------END OF SCRIPT; CHECK FOR ERRORS---------------------------------------#"
echo "############################################################################################################"
