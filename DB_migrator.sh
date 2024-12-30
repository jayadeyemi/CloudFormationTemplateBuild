# ----------------------------------------------------------
# Variable Definitions
# ----------------------------------------------------------
# Contents of 
# EC2 Instance Private IP Address (Modify as needed)

# RDS Instance Connection Details
EC2V1PrivateIP="192.168.2.23"
RDS_Endpoint=""
SECRETUSERNAME=""
SECRETPASSWORD=""

aws secretsmanager get-secret-value --secret-id RSA_KEYS --query PUBLIC --output text > ec2v1_key.pem

# Create a new Secret for RDS
SECRET_USERNAME=aws secretsmanager get-secret-value --secret-id "Mydbsecret" --query 'SecretString.user' --output text
SECRET_PASSWORD=aws secretsmanager get-secret-value --secret-id "Mydbsecret" --query 'SecretString.password' --output text
RDS_ENDPOINT=aws secretsmanager get-secret-value --secret-id "Mydbsecret" --query 'SecretString.host' --output text
SECRET_PASSWORD=aws secretsmanager get-secret-value --secret-id "Mydbsecret" --query 'SecretString.db' --output text
# ----------------------------------------------------------
# 2) OBTAIN SSH PRIVATE KEY FROM SECRETS MANAGER
# ----------------------------------------------------------
aws secretsmanager get-secret-value \
  --secret-id RSA_KEYS \
  --query 'SecretString.PUBLIC' \ > ec2v1_key.pem
chmod 400 ec2v1_key.pem
# # ----------------------------------------------------------
# # 2) CREATE MySQL DUMP ON EC2V1, THEN COPY BACK TO EPHEMERAL_EC2
# # ----------------------------------------------------------
# echo "Creating MySQL dump on EC2V1..."

# ssh -o "StrictHostKeyChecking=no" \
#     -i ec2v1_key.pem \
#     ubuntu@$EC2V1PrivateIP \
#     "mysqldump -h localhost -u nodeapp -pstudent12 --databases STUDENTS > /tmp/data.sql"

# echo "MySQL dump created on EC2V1. Copying data.sql to EphemeralEC2..."
# scp -o "StrictHostKeyChecking=no" \
#     -i ec2v1_key.pem \
#     ubuntu@$EC2V1PrivateIP:/tmp/data.sql data.sql

# # ----------------------------------------------------------
# # 3) IMPORT MySQL DUMP INTO RDS
# # ----------------------------------------------------------
# echo "Importing MySQL dump into RDS from EphemeralEC2..."
# mysql -h $RDS_Endpoint -u $SECRETUSERNAME -p$SECRETPASSWORD -e "CREATE DATABASE STUDENTS;"
# mysql -h $RDS_Endpoint -u $SECRETUSERNAME -p$SECRETPASSWORD STUDENTS < data.sql

# echo "All ephemeral tasks completed."
# Optional: self-terminate after completion:
# shutdown -h now