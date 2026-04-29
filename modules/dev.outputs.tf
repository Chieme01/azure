output "test" {
  value = templatefile("${path.module}/scripts/bootstrap-kubernetes.sh", var.cluster_config)
}