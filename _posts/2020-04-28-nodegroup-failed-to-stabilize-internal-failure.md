---
layout : post
title: "Cloudformation - NodeGroup failed to stabilize: Internal Failure"
date: 2020-04-28 09:00:00
categories: kubernetes
biofooter: true
bookfooter: false
docker_book_footer: false
---

A recent change to AWS NodeGroup behaviour means that some CloudFormation stacks which create EKS NodeGroups may start to fail with the error `Nodegroup the-nodegroup-name failed to stabilize: Internal Failure`. Googling currently doesn't return much. The problem is related to [this change](https://aws.amazon.com/blogs/containers/upcoming-changes-to-ip-assignment-for-eks-managed-node-groups/) relating to whether or not public IP's are assigned to nodes.

<!--more-->

Prior to April 22nd, managed node groups always assign public IP's to nodes, irrespective of the value of `MapPublicIpOnLaunch` on the associated subnet. Going forward public IP's will only be assigned if `MapPublicIpOnLaunch` is `true` on the associated subnet.

So if creating the subnet via Cloudformation, we previously had:

```
Subnet1a:
  Type: AWS::EC2::Subnet
  Properties:
    VpcId: !Ref VPC
    AvailabilityZone:
      Fn::Sub: '${Region}a'
    CidrBlock: 172.16.0.0/18
```

We would now need to add the final line as below:

```
Subnet1a:
  Type: AWS::EC2::Subnet
  Properties:
    VpcId: !Ref VPC
    AvailabilityZone:
      Fn::Sub: '${Region}a'
    CidrBlock: 172.16.0.0/18
    MapPublicIpOnLaunch: true
```

For our existing configuration to continue working. More info is [in the AWS post](https://aws.amazon.com/blogs/containers/upcoming-changes-to-ip-assignment-for-eks-managed-node-groups/).

The trick to debugging turned out to be setting `disable_rollback` to `true` (if using Ansible to manage Cloudformation) so that the NodeGroup wasn't deleted on failure making it possible to go in and inspect the NodeGroup.