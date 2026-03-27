environment                   = "dev"
location                      = "centralus"
name_prefix                   = "neuro-san"
container_cpu                 = 0.5
container_memory              = "1Gi"
container_min_replicas        = 1
container_max_replicas        = 2
foundry_model_capacity        = 1
foundry_model_deployment_name = "gpt-5.2"
tags = {
  workload_tier = "development"
}