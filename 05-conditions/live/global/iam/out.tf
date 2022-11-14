output "first_arn" {
  value = aws_iam_user.this[0].arn
  description = "The ARN for the firs user"
}

output "all_arns" {
  value = aws_iam_user.this[*].arn
  description = "The ARNs for all the users"
}