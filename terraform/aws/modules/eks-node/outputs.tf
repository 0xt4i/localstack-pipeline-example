output "worker_node_security_group_id" {
  description = "Worker node security group ID"
  value       = aws_security_group.worker_sg.id
}
