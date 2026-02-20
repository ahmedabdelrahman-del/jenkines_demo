output "addons_enabled" {
  value = {
    metrics_server               = true
    aws_load_balancer_controller = true
    ebs_csi_driver               = true
  }
}
