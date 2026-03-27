environment                   = "prod"
location                      = "centralus"
name_prefix                   = "neuro-san"
container_cpu                 = 1
container_memory              = "2Gi"
container_min_replicas        = 2
container_max_replicas        = 5
foundry_model_capacity        = 5
foundry_model_deployment_name = "gpt-5.2"
tags = {
  workload_tier = "production"
}