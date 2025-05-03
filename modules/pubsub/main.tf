resource "google_pubsub_topic" "topic" {
  name = var.topic_name
}

output "topic_name" {
  value = google_pubsub_topic.topic.name
}
