resource "aws_sns_topic" "pipeline_notifications" {
  name = "luxe-pipeline-notifications"
  
  tags = {
    Project = "LuxeJewelry"
  }
}

# Output the ARN so you can use it in your Jenkinsfile/GitHub Actions later
output "sns_topic_arn" {
  value = aws_sns_topic.pipeline_notifications.arn
}