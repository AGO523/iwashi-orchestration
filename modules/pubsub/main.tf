resource "google_pubsub_topic" "topic" {
  name = var.topic_name
}

# resource "google_pubsub_topic_iam_member" "api_gateway_publish" {
#   topic  = google_pubsub_topic.topic.name
#   role   = "roles/pubsub.publisher"
#   member = "serviceAccount:service-${var.project_id}@apigateway-robot.iam.gserviceaccount.com"
# }

output "topic_name" {
  value = google_pubsub_topic.topic.name
}
