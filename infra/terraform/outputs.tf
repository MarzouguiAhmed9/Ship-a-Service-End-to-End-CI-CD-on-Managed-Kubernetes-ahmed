
# Private ECR registry URL
output "registry_url" {
  value = aws_ecr_repository.app.repository_url
}

output "cluster_name" {
  value = module.eks.cluster_id
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "kubeconfig_yaml" {
  value = <<EOT
apiVersion: v1
clusters:
- cluster:
    server: ${module.eks.cluster_endpoint}
    certificate-authority-data: ${module.eks.cluster_certificate_authority_data}
  name: ${module.eks.cluster_id}
contexts:
- context:
    cluster: ${module.eks.cluster_id}
    user: aws
  name: ${module.eks.cluster_id}
current-context: ${module.eks.cluster_id}
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - eks
        - get-token
        - --cluster-name
        - ${module.eks.cluster_id}
EOT
  sensitive = true
  #k
}
