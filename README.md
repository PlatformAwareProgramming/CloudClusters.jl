# CloudClusters.jl

## Instâncias da AWS

O seguinte comando lista a memória e as configurações de CPU para cada instância da AWS:

```bash
aws ec2 describe-instance-types | jq '.InstanceTypes[] | {Instancia: .InstanceType, Cores: .VCpuInfo.DefaultCores, Threads: .VCpuInfo.DefaultVCpus, Memoria:.MemoryInfo.SizeInMiB}'
```

Outros campos podem ser adicionados, como verificar se a instância tem GPU ou suporta determinada configuração de rede. Abaixo o exemplo da informação completa disponível para uma instância. É um JSON que
pode ser carregado em um dicionário.

```json
{
            "InstanceType": "g5.4xlarge",
            "CurrentGeneration": true,
            "FreeTierEligible": false,
            "SupportedUsageClasses": [
                "on-demand",
                "spot"
            ],
            "SupportedRootDeviceTypes": [
                "ebs"
            ],
            "SupportedVirtualizationTypes": [
                "hvm"
            ],
            "BareMetal": false,
            "Hypervisor": "nitro",
            "ProcessorInfo": {
                "SupportedArchitectures": [
                    "x86_64"
                ],
                "SustainedClockSpeedInGhz": 3.3
            },
            "VCpuInfo": {
                "DefaultVCpus": 16,
                "DefaultCores": 8,
                "DefaultThreadsPerCore": 2
            },
            "MemoryInfo": {
                "SizeInMiB": 65536
            },
            "InstanceStorageSupported": true,
            "InstanceStorageInfo": {
                "TotalSizeInGB": 600,
                "Disks": [
                    {
                        "SizeInGB": 600,
                        "Count": 1,
                        "Type": "ssd"
                    }
                ]
            },
            "EbsInfo": {
                "EbsOptimizedSupport": "default",
                "EncryptionSupport": "supported",
                "EbsOptimizedInfo": {
                    "BaselineBandwidthInMbps": 4750,
                    "BaselineThroughputInMBps": 593.75,
                    "BaselineIops": 20000,
                    "MaximumBandwidthInMbps": 4750,
                    "MaximumThroughputInMBps": 593.75,
                    "MaximumIops": 20000
                }
            },
            "NetworkInfo": {
                "NetworkPerformance": "Up to 25 Gigabit",
                "MaximumNetworkInterfaces": 8,
                "Ipv4AddressesPerInterface": 30,
                "Ipv6AddressesPerInterface": 30,
                "Ipv6Supported": true,
                "EnaSupport": "required",
                "EfaSupported": false
            },
            "GpuInfo": {
                "Gpus": [
                    {
                        "Name": "A10G",
                        "Manufacturer": "NVIDIA",
                        "Count": 1,
                        "MemoryInfo": {
                            "SizeInMiB": 24576
                        }
                    }
                ],
                "TotalGpuMemoryInMiB": 24576
            },
            "PlacementGroupInfo": {
                "SupportedStrategies": [
                    "cluster",
                    "partition",
                    "spread"
                ]
            },
          "HibernationSupported": false,
          "BurstablePerformanceSupported": false,
          "DedicatedHostsSupported": false,
          "AutoRecoverySupported": false
},
```
