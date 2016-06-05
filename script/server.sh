#!/bin/bash -e
#
# Creating and Terminating a server from the CLI 
# You need to install the AWS Command Line Interface from http://aws.amazon.com/cli/
# to install it, you need to have python and pip installed
#
# python --version
# pip -- version
#
# sudo python get-pip.py
# sudo pip install awscli


echo "== Init Variables ==" 

# Get the ID of the Amazon Linux Image
AMIID=$(aws ec2 describe-images --filters "Name=description, Values=Amazon Linux AMI 2015.03.? x86_64 HVM GP2" --query "Images[0].ImageId" --output text)
echo "- define amazon image id: $AMIID"

# Get the default VPC ID
VPCID=$(aws ec2 describe-vpcs --filter "Name=isDefault, Values=true" --query "Vpcs[0].VpcId" --output text)
echo "- define vpc id: $VPCID"

# Get the defaul subnet ID
SUBNETID=$(aws ec2 describe-subnets --filters "Name=vpc-id, Values=$VPCID" --query "Subnets[0].SubnetId" --output text)
echo "- define subnet id: $SUBNETID"


# Create the security group
SGID=$(aws ec2 create-security-group --group-name securitygroupCreatedByScript --description "My security group" --vpc-id $VPCID --output text)
echo "- create security id: $SGID"

# Allow inbound SSH connections 
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol tcp --port 22 --cidr 0.0.0.0/0
 
echo "== Create and start server"

INSTANCEID=$(aws ec2 run-instances --image-id $AMIID --key-name myKey --instance-type t2.micro --security-group-ids $SGID --subnet-id $SUBNETID --query "Instances[0].InstanceId" --output text)

echo "- waiting for $INSTANCEID ..."
aws ec2 wait instance-running --instance-ids $INSTANCEID

# Get the public name of the server
PUBLICNAME=$(aws ec2 describe-instances --instance-ids $INSTANCEID --query "Reservations[0].Instances[0].PublicDnsName" --output text)

echo "$INSTANCEID is accepting SSH connections under $PUBLICNAME"
echo "ssh -i myKey.pem ec2-user@$PUBLICNAME"
read -p "Press [Enter] key to terminate $INSTANCEID ..."

# Terminate the server
aws ec2 terminate-instances --instance-ids $INSTANCEID
echo "== terminating $INSTANCEID ..."

# Wait until the server is terminated
echo "- waiting for termination"
aws ec2 wait instance-terminated --instance-ids $INSTANCEID

# Delete the security group
echo "- deleting security group"
aws ec2 delete-security-group --group-id $SGID
echo "done."
















