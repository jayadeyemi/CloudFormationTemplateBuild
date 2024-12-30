# CloudFormation Workspace Documentation

## Overview

This document provides a guide for deploying a 3-phase AWS infrastructure using CloudFormation templates. The setup includes EC2 instances, networking components, a MySQL RDS database, and an Auto Scaling environment. A migration script is included to transfer data from an EC2-hosted MySQL instance to the RDS instance.

## Files

- **Phase1.yml**  
  Sets up a public subnet and an EC2 instance running MySQL.
- **Phase2.yml**  
  Creates an RDS instance and securely stores credentials in AWS Secrets Manager.
- **Phase3.yml**  
  Configures an Application Load Balancer, Auto Scaling Group, and security groups to ensure high availability.
- **DB_migrator.sh**  
  Automates data migration from the Phase1 EC2 instance to the RDS instance.

## Usage

### 1. Create S3 Bucket
Upload `Phase1.yml`, `Phase2.yml`, and `Phase3.yml` to an S3 bucket for easy access during stack creation.

### 2. Create Key Pairs
Generate two EC2 Key Pairs: one for instances in public subnets and another for instances in private subnets. 

### 3. Store Key Pairs in Secrets Manager

- Save the Key Pair files and store their contents in AWS Secrets Manager.
- The `DB_migrator.sh` script expects the following secret structure:
  ```json
  {
      "RSA_KEYS": {
          "Key": "Value",
          "PUBLIC": "-----BEGIN RSA-----\nMIIEowIBAA... ...KCAQEAqz9z\n-----END RSA-----",
          "PRIVATE": "-----BEGIN RSA-----\nMIIEowIBAA... ...KCAQEAqz9z\n-----END RSA-----"
      }
  }

### 4. Launch Phase1 CloudFormation Stack

- Deploy the `Phase1.yml` CloudFormation stack. This stack will create nested stacks for `Phase2.yml` and `Phase3.yml`.
- Ensure an IAM role with the necessary permissions is attached to the stack.

### 5. Verify Stack Outputs

- Wait for all stack deployments to complete.
- Review the output values of each stack for key information, such as web application URLs and RDS instance details.

### 6. Create a Migration Environment

- Set up a Cloud9 environment or launch an ephemeral EC2 instance to run the migration script.

### 7. Link Security Groups

- Update security group configurations to allow the Cloud9 or EC2 instance to communicate with the Phase1 EC2 instance (hosting the local MySQL database) and the RDS instance.

### 8. Run Migration Script

- Execute the `DB_migrator.sh` script on the Cloud9 or EC2 instance. The script will automatically transfer data from the local MySQL database to the RDS instance.

## Conclusion

By following this guide, you can deploy a scalable and highly available AWS infrastructure with ease. The included migration script simplifies the process of moving data to the cloud, ensuring a seamless transition. For any issues or further customization, refer to AWS documentation or consult your AWS administrator.
