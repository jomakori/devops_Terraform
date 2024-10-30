/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ EC2 Gateway - Networking Dependencies                                    │
  └──────────────────────────────────────────────────────────────────────────┘
 */
data "aws_vpc" "gateway_vpc" {
  id = "vpc-c5a620a0"
}
data "aws_subnet" "gateway_pub_subnet" {
  vpc_id = data.aws_vpc.gateway_vpc.id

  tags = {
    subnet = "public"
  }
}


# Tower Region
data "aws_region" "current" {}

