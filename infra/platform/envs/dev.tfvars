env           = "dev"
node_capacity = "ON_DEMAND"
node_desired  = 1
# Add each member's IAM user ARN so they can use kubectl from their laptop:
admin_principal_arns = [
  # "arn:aws:iam::<ACCOUNT_ID>:user/member1",
]
