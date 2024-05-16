#= 14/05/2024 - https://docs.aws.amazon.com/ec2/latest/instancetypes/instance-types.html

CURRENT GENERATION

General purpose: M5 | M5a | M5ad | M5d | M5dn | M5n | M5zn | M6a | M6g | M6gd | M6i | M6id | M6idn | M6in | M7a | M7g | M7gd | M7i | M7i-flex | Mac1 | Mac2 | Mac2-m2 | Mac2-m2pro | T2 | T3 | T3a | T4g

Compute optimized: C5 | C5a | C5ad | C5d | C5n | C6a | C6g | C6gd | C6gn | C6i | C6id | C6in | C7a | C7g | C7gd | C7gn | C7i

Memory optimized: R5 | R5a | R5ad | R5b | R5d | R5dn | R5n | R6a | R6g | R6gd | R6i | R6idn | R6in | R6id | R7a | R7g | R7gd | R7i | R7iz | U-3tb1 | U-6tb1 | U-9tb1 | U-12tb1 | U-18tb1 | U-24tb1 | X1 | X2gd | X2idn | X2iedn | X2iezn | X1e | z1d

Storage optimized: D2 | D3 | D3en | H1 | I3 | I3en | I4g | I4i | Im4gn | Is4gen

Accelerated computing: DL1 | DL2q | F1 | G4ad | G4dn | G5 | G5g | G6 | Gr6 | Inf1 | Inf2 | P2 | P3 | P3dn | P4d | P4de | P5 | Trn1 | Trn1n | VT1

High-performance computing: Hpc6a | Hpc6id | Hpc7a | Hpc7g

PREVIOUS GENERATION

General purpose: A1 | M1 | M2 | M3 | M4 | T1

Compute optimized: C1 | C3 | C4

Memory optimized: R3 | R4

Storage optimized: I2

Accelerated computing: G3

=#


# instance type families

abstract type FEC2InstanceType <: FInstanceType end


abstract type FEC2GeneralInstanceType <: FEC2InstanceType end
abstract type FEC2ComputeInstanceType <: FEC2InstanceType end
abstract type FEC2MemoryInstanceType <: FEC2InstanceType end
abstract type FEC2StorageInstanceType <: FEC2InstanceType end
abstract type FEC2AcceleratedInstanceType <: FEC2InstanceType end
abstract type FEC2HPCInstanceType <: FEC2InstanceType end

# general purpose instance types

abstract type FEC2_M5 <: FEC2GeneralInstanceType end
abstract type FEC2_M5a <: FEC2GeneralInstanceType end
abstract type FEC2_M5ad <: FEC2GeneralInstanceType end
abstract type FEC2_M5d <: FEC2GeneralInstanceType end
abstract type FEC2_M5dn <: FEC2GeneralInstanceType end
abstract type FEC2_M5n <: FEC2GeneralInstanceType end
abstract type FEC2_M5zn <: FEC2GeneralInstanceType end
abstract type FEC2_M6a <: FEC2GeneralInstanceType end
abstract type FEC2_M6g <: FEC2GeneralInstanceType end
abstract type FEC2_M6gd <: FEC2GeneralInstanceType end
abstract type FEC2_M6i <: FEC2GeneralInstanceType end
abstract type FEC2_M6id <: FEC2GeneralInstanceType end
abstract type FEC2_M6idn <: FEC2GeneralInstanceType end
abstract type FEC2_M6in <: FEC2GeneralInstanceType end
abstract type FEC2_M7a <: FEC2GeneralInstanceType end
abstract type FEC2_M7g <: FEC2GeneralInstanceType end
abstract type FEC2_M7gd <: FEC2GeneralInstanceType end
abstract type FEC2_M7i <: FEC2GeneralInstanceType end
abstract type FEC2_M7iflex <: FEC2GeneralInstanceType end
abstract type FEC2_Mac1 <: FEC2GeneralInstanceType end
abstract type FEC2_Mac2 <: FEC2GeneralInstanceType end
abstract type FEC2_Mac2m2 <: FEC2GeneralInstanceType end
abstract type FEC2_Mac2m2pro <: FEC2GeneralInstanceType end
abstract type FEC2_T2 <: FEC2GeneralInstanceType end
abstract type FEC2_T3 <: FEC2GeneralInstanceType end
abstract type FEC2_T3a <: FEC2GeneralInstanceType end
abstract type FEC2_T4g <: FEC2GeneralInstanceType end

abstract type FEC2_A1 <: FEC2GeneralInstanceType end  # previous
abstract type FEC2_M1 <: FEC2GeneralInstanceType end  # previous
abstract type FEC2_M2 <: FEC2GeneralInstanceType end  # previous
abstract type FEC2_M3 <: FEC2GeneralInstanceType end  # previous
abstract type FEC2_M4 <: FEC2GeneralInstanceType end  # previous
abstract type FEC2_T1 <: FEC2GeneralInstanceType end  # previous

# compute optimized instance types

abstract type FEC2_C5 <: FEC2ComputeInstanceType end
abstract type FEC2_C5a <: FEC2ComputeInstanceType end
abstract type FEC2_C5ad <: FEC2ComputeInstanceType end
abstract type FEC2_C5d <: FEC2ComputeInstanceType end
abstract type FEC2_C5n <: FEC2ComputeInstanceType end
abstract type FEC2_C6 <: FEC2ComputeInstanceType end
abstract type FEC2_C6a <: FEC2ComputeInstanceType end
abstract type FEC2_C6g <: FEC2ComputeInstanceType end
abstract type FEC2_C6gd <: FEC2ComputeInstanceType end
abstract type FEC2_C6gn <: FEC2ComputeInstanceType end
abstract type FEC2_C6i <: FEC2ComputeInstanceType end
abstract type FEC2_C6id <: FEC2ComputeInstanceType end
abstract type FEC2_C6in <: FEC2ComputeInstanceType end
abstract type FEC2_C7 <: FEC2ComputeInstanceType end
abstract type FEC2_C7a <: FEC2ComputeInstanceType end
abstract type FEC2_C7g <: FEC2ComputeInstanceType end
abstract type FEC2_C7gd <: FEC2ComputeInstanceType end
abstract type FEC2_C7gn <: FEC2ComputeInstanceType end
abstract type FEC2_C7i <: FEC2ComputeInstanceType end

abstract type FEC2_C1 <: FEC2ComputeInstanceType end   # previous
abstract type FEC2_C3 <: FEC2ComputeInstanceType end   # previous
abstract type FEC2_C4 <: FEC2ComputeInstanceType end   # previous

# memory optimized instance types

abstract type FEC2_R5 <: FEC2MemoryInstanceType end
abstract type FEC2_R5a <: FEC2MemoryInstanceType end
abstract type FEC2_R5ad <: FEC2MemoryInstanceType end
abstract type FEC2_R5b <: FEC2MemoryInstanceType end
abstract type FEC2_R5d <: FEC2MemoryInstanceType end
abstract type FEC2_R5dn <: FEC2MemoryInstanceType end
abstract type FEC2_R5n <: FEC2MemoryInstanceType end
abstract type FEC2_R6a <: FEC2MemoryInstanceType end
abstract type FEC2_R6g <: FEC2MemoryInstanceType end
abstract type FEC2_R6gd <: FEC2MemoryInstanceType end
abstract type FEC2_R6i <: FEC2MemoryInstanceType end
abstract type FEC2_R6idn <: FEC2MemoryInstanceType end
abstract type FEC2_R6in <: FEC2MemoryInstanceType end
abstract type FEC2_R6id <: FEC2MemoryInstanceType end
abstract type FEC2_R7a <: FEC2MemoryInstanceType end
abstract type FEC2_R7g <: FEC2MemoryInstanceType end
abstract type FEC2_R7gd <: FEC2MemoryInstanceType end
abstract type FEC2_R7i <: FEC2MemoryInstanceType end
abstract type FEC2_R7iz <: FEC2MemoryInstanceType end
abstract type FEC2_U3tb1 <: FEC2MemoryInstanceType end
abstract type FEC2_U6tb1 <: FEC2MemoryInstanceType end
abstract type FEC2_U9tb1 <: FEC2MemoryInstanceType end
abstract type FEC2_U12tb1 <: FEC2MemoryInstanceType end
abstract type FEC2_U18tb1 <: FEC2MemoryInstanceType end
abstract type FEC2_U24tb1 <: FEC2MemoryInstanceType end
abstract type FEC2_X1 <: FEC2MemoryInstanceType end
abstract type FEC2_X2gd <: FEC2MemoryInstanceType end
abstract type FEC2_X2idn <: FEC2MemoryInstanceType end
abstract type FEC2_X2iedn <: FEC2MemoryInstanceType end
abstract type FEC2_X2iezn <: FEC2MemoryInstanceType end
abstract type FEC2_X1e <: FEC2MemoryInstanceType end
abstract type FEC2_z1d <: FEC2MemoryInstanceType end

abstract type FEC2_R3 <: FEC2MemoryInstanceType end           # previous
abstract type FEC2_R4 <: FEC2MemoryInstanceType end           # previous


# storage optimized instance types

abstract type FEC2_D2 <: FEC2StorageInstanceType end
abstract type FEC2_D3 <: FEC2StorageInstanceType end
abstract type FEC2_D3en <: FEC2StorageInstanceType end
abstract type FEC2_H1 <: FEC2StorageInstanceType end
abstract type FEC2_I3 <: FEC2StorageInstanceType end
abstract type FEC2_I3en <: FEC2StorageInstanceType end
abstract type FEC2_I4g <: FEC2StorageInstanceType end
abstract type FEC2_I4i <: FEC2StorageInstanceType end
abstract type FEC2_Im4gn <: FEC2StorageInstanceType end
abstract type FEC2_Is4gen <: FEC2StorageInstanceType end

abstract type FEC2_I2 <: FEC2StorageInstanceType end        # previous

# acelerated instance types

abstract type FEC2_DL1 <: FEC2AcceleratedInstanceType end
abstract type FEC2_DL2q <: FEC2AcceleratedInstanceType end  ###
abstract type FEC2_F1 <: FEC2AcceleratedInstanceType end
abstract type FEC2_G4ad <: FEC2AcceleratedInstanceType end
abstract type FEC2_G4dn <: FEC2AcceleratedInstanceType end
abstract type FEC2_G5 <: FEC2AcceleratedInstanceType end
abstract type FEC2_G5g <: FEC2AcceleratedInstanceType end
abstract type FEC2_G6 <: FEC2AcceleratedInstanceType end
abstract type FEC2_Gr6 <: FEC2AcceleratedInstanceType end
abstract type FEC2_Inf1 <: FEC2AcceleratedInstanceType end
abstract type FEC2_Inf2 <: FEC2AcceleratedInstanceType end
abstract type FEC2_Inf3 <: FEC2AcceleratedInstanceType end
abstract type FEC2_Inf4 <: FEC2AcceleratedInstanceType end
abstract type FEC2_Inf5 <: FEC2AcceleratedInstanceType end
abstract type FEC2_P2 <: FEC2AcceleratedInstanceType end
abstract type FEC2_P3 <: FEC2AcceleratedInstanceType end
abstract type FEC2_P3dn <: FEC2AcceleratedInstanceType end
abstract type FEC2_P4d <: FEC2AcceleratedInstanceType end
abstract type FEC2_P4de <: FEC2AcceleratedInstanceType end
abstract type FEC2_P5 <: FEC2AcceleratedInstanceType end
abstract type FEC2_Trn1 <: FEC2AcceleratedInstanceType end
abstract type FEC2_Trn1n <: FEC2AcceleratedInstanceType end
abstract type FEC2_VT1 <: FEC2AcceleratedInstanceType end

abstract type FEC2_G2 <: FEC2AcceleratedInstanceType end      # previous
abstract type FEC2_G3 <: FEC2AcceleratedInstanceType end      # previous
abstract type FEC2_G3s <: FEC2AcceleratedInstanceType end      # previous

# HPC instance types

abstract type FEC2_Hpc6a <: FEC2HPCInstanceType end
abstract type FEC2_Hpc6id <: FEC2HPCInstanceType end
abstract type FEC2_Hpc7a <: FEC2HPCInstanceType end
abstract type FEC2_Hpc7g <: FEC2HPCInstanceType end

# unrecognized instance type

abstract type FEC2_Cc2 <: FEC2InstanceType end
abstract type FEC2_Cr1 <: FEC2InstanceType end
abstract type FEC2_Hs1 <: FEC2InstanceType end


### INSTANCE SIZES

abstract type FEC2_A1_medium <: FEC2_A1 end
abstract type FEC2_A1_4xlarge <: FEC2_A1 end
abstract type FEC2_A1_2xlarge <: FEC2_A1 end
abstract type FEC2_A1_xlarge <: FEC2_A1 end
abstract type FEC2_A1_large <: FEC2_A1 end
abstract type FEC2_A1_metal <: FEC2_A1 end

abstract type FEC2_C1_xlarge <: FEC2_C1 end
abstract type FEC2_C1_medium <: FEC2_C1 end

abstract type FEC2_C3_8xlarge <: FEC2_C3 end

abstract type FEC2_C6_xlarge <: FEC2_C6 end

abstract type FEC2_C7_large <: FEC2_C7 end

abstract type FEC2_C4_8xlarge <: FEC2_C4 end
abstract type FEC2_C4_4xlarge <: FEC2_C4 end
abstract type FEC2_C4_2xlarge <: FEC2_C4 end
abstract type FEC2_C4_xlarge <: FEC2_C4 end
abstract type FEC2_C4_large <: FEC2_C4 end

abstract type FEC2_C5_metal <: FEC2_C5 end
abstract type FEC2_C5_24xlarge <: FEC2_C5 end
abstract type FEC2_C5_2xlarge <: FEC2_C5 end
abstract type FEC2_C5_18xlarge <: FEC2_C5 end
abstract type FEC2_C5_12xlarge <: FEC2_C5 end
abstract type FEC2_C5_9xlarge <: FEC2_C5 end
abstract type FEC2_C5_4xlarge <: FEC2_C5 end
abstract type FEC2_C5_xlarge <: FEC2_C5 end
abstract type FEC2_C5_large <: FEC2_C5 end

abstract type FEC2_C5a_24xlarge <: FEC2_C5a end
abstract type FEC2_C5a_12xlarge <: FEC2_C5a end
abstract type FEC2_C5a_xlarge <: FEC2_C5a end
abstract type FEC2_C5a_8xlarge <: FEC2_C5a end
abstract type FEC2_C5a_2xlarge <: FEC2_C5a end
abstract type FEC2_C5a_large <: FEC2_C5a end
abstract type FEC2_C5a_16xlarge <: FEC2_C5a end
abstract type FEC2_C5a_4xlarge <: FEC2_C5a end

abstract type FEC2_C5ad_large <: FEC2_C5ad end
abstract type FEC2_C5ad_8xlarge <: FEC2_C5ad end
abstract type FEC2_C5ad_4xlarge <: FEC2_C5ad end
abstract type FEC2_C5ad_2xlarge <: FEC2_C5ad end
abstract type FEC2_C5ad_24xlarge <: FEC2_C5ad end
abstract type FEC2_C5ad_xlarge <: FEC2_C5ad end
abstract type FEC2_C5ad_12xlarge <: FEC2_C5ad end
abstract type FEC2_C5ad_16xlarge <: FEC2_C5ad end

abstract type FEC2_C5d_24xlarge <: FEC2_C5d end
abstract type FEC2_C5d_metal <: FEC2_C5d end
abstract type FEC2_C5d_18xlarge <: FEC2_C5d end
abstract type FEC2_C5d_12xlarge <: FEC2_C5d end
abstract type FEC2_C5d_9xlarge <: FEC2_C5d end
abstract type FEC2_C5d_4xlarge <: FEC2_C5d end
abstract type FEC2_C5d_2xlarge <: FEC2_C5d end
abstract type FEC2_C5d_xlarge <: FEC2_C5d end
abstract type FEC2_C5d_large <: FEC2_C5d end

abstract type FEC2_C5n_18xlarge <: FEC2_C5n end
abstract type FEC2_C5n_9xlarge <: FEC2_C5n end
abstract type FEC2_C5n_4xlarge <: FEC2_C5n end
abstract type FEC2_C5n_2xlarge <: FEC2_C5n end
abstract type FEC2_C5n_xlarge <: FEC2_C5n end
abstract type FEC2_C5n_large <: FEC2_C5n end
abstract type FEC2_C5n_metal <: FEC2_C5n end

abstract type FEC2_C6a_32xlarge <: FEC2_C6a end
abstract type FEC2_C6a_large <: FEC2_C6a end
abstract type FEC2_C6a_16xlarge <: FEC2_C6a end
abstract type FEC2_C6a_xlarge <: FEC2_C6a end
abstract type FEC2_C6a_8xlarge <: FEC2_C6a end
abstract type FEC2_C6a_48xlarge <: FEC2_C6a end
abstract type FEC2_C6a_4xlarge <: FEC2_C6a end
abstract type FEC2_C6a_metal <: FEC2_C6a end
abstract type FEC2_C6a_2xlarge <: FEC2_C6a end
abstract type FEC2_C6a_12xlarge <: FEC2_C6a end
abstract type FEC2_C6a_24xlarge <: FEC2_C6a end

abstract type FEC2_C6g_xlarge <: FEC2_C6g end
abstract type FEC2_C6g_medium <: FEC2_C6g end
abstract type FEC2_C6g_12xlarge <: FEC2_C6g end
abstract type FEC2_C6g_8xlarge <: FEC2_C6g end
abstract type FEC2_C6g_16xlarge <: FEC2_C6g end
abstract type FEC2_C6g_large <: FEC2_C6g end
abstract type FEC2_C6g_metal <: FEC2_C6g end
abstract type FEC2_C6g_4xlarge <: FEC2_C6g end
abstract type FEC2_C6g_2xlarge <: FEC2_C6g end

abstract type FEC2_C6gd_xlarge <: FEC2_C6gd end
abstract type FEC2_C6gd_large <: FEC2_C6gd end
abstract type FEC2_C6gd_16xlarge <: FEC2_C6gd end
abstract type FEC2_C6gd_8xlarge <: FEC2_C6gd end
abstract type FEC2_C6gd_2xlarge <: FEC2_C6gd end
abstract type FEC2_C6gd_12xlarge <: FEC2_C6gd end
abstract type FEC2_C6gd_medium <: FEC2_C6gd end
abstract type FEC2_C6gd_4xlarge <: FEC2_C6gd end
abstract type FEC2_C6gd_metal <: FEC2_C6gd end

abstract type FEC2_C6gn_12xlarge <: FEC2_C6gn end
abstract type FEC2_C6gn_large <: FEC2_C6gn end
abstract type FEC2_C6gn_4xlarge <: FEC2_C6gn end
abstract type FEC2_C6gn_8xlarge <: FEC2_C6gn end
abstract type FEC2_C6gn_medium <: FEC2_C6gn end
abstract type FEC2_C6gn_2xlarge <: FEC2_C6gn end
abstract type FEC2_C6gn_xlarge <: FEC2_C6gn end
abstract type FEC2_C6gn_16xlarge <: FEC2_C6gn end

abstract type FEC2_C6i_large <: FEC2_C6i end
abstract type FEC2_C6i_16xlarge <: FEC2_C6i end
abstract type FEC2_C6i_xlarge <: FEC2_C6i end
abstract type FEC2_C6i_24xlarge <: FEC2_C6i end
abstract type FEC2_C6i_metal <: FEC2_C6i end
abstract type FEC2_C6i_2xlarge <: FEC2_C6i end
abstract type FEC2_C6i_8xlarge <: FEC2_C6i end
abstract type FEC2_C6i_12xlarge <: FEC2_C6i end
abstract type FEC2_C6i_32xlarge <: FEC2_C6i end
abstract type FEC2_C6i_4xlarge <: FEC2_C6i end

abstract type FEC2_C6id_12xlarge <: FEC2_C6id end
abstract type FEC2_C6id_32xlarge <: FEC2_C6id end
abstract type FEC2_C6id_metal <: FEC2_C6id end
abstract type FEC2_C6id_large <: FEC2_C6id end
abstract type FEC2_C6id_4xlarge <: FEC2_C6id end
abstract type FEC2_C6id_24xlarge <: FEC2_C6id end
abstract type FEC2_C6id_2xlarge <: FEC2_C6id end
abstract type FEC2_C6id_xlarge <: FEC2_C6id end
abstract type FEC2_C6id_8xlarge <: FEC2_C6id end
abstract type FEC2_C6id_16xlarge <: FEC2_C6id end

abstract type FEC2_C6in_metal <: FEC2_C6in end
abstract type FEC2_C6in_2xlarge <: FEC2_C6in end
abstract type FEC2_C6in_large <: FEC2_C6in end
abstract type FEC2_C6in_4xlarge <: FEC2_C6in end
abstract type FEC2_C6in_12xlarge <: FEC2_C6in end
abstract type FEC2_C6in_24xlarge <: FEC2_C6in end
abstract type FEC2_C6in_8xlarge <: FEC2_C6in end
abstract type FEC2_C6in_16xlarge <: FEC2_C6in end
abstract type FEC2_C6in_xlarge <: FEC2_C6in end
abstract type FEC2_C6in_32xlarge <: FEC2_C6in end

abstract type FEC2_C7a_8xlarge <: FEC2_C7a end
abstract type FEC2_C7a_metal48xl <: FEC2_C7a end
abstract type FEC2_C7a_medium <: FEC2_C7a end
abstract type FEC2_C7a_32xlarge <: FEC2_C7a end
abstract type FEC2_C7a_large <: FEC2_C7a end
abstract type FEC2_C7a_4xlarge <: FEC2_C7a end
abstract type FEC2_C7a_24xlarge <: FEC2_C7a end
abstract type FEC2_C7a_12xlarge <: FEC2_C7a end
abstract type FEC2_C7a_48xlarge <: FEC2_C7a end
abstract type FEC2_C7a_2xlarge <: FEC2_C7a end
abstract type FEC2_C7a_16xlarge <: FEC2_C7a end
abstract type FEC2_C7a_xlarge <: FEC2_C7a end

abstract type FEC2_C7g_8xlarge <: FEC2_C7g end
abstract type FEC2_C7g_4xlarge <: FEC2_C7g end
abstract type FEC2_C7g_medium <: FEC2_C7g end
abstract type FEC2_C7g_12xlarge <: FEC2_C7g end
abstract type FEC2_C7g_large <: FEC2_C7g end
abstract type FEC2_C7g_xlarge <: FEC2_C7g end
abstract type FEC2_C7g_2xlarge <: FEC2_C7g end
abstract type FEC2_C7g_16xlarge <: FEC2_C7g end
abstract type FEC2_C7g_metal <: FEC2_C7g end

abstract type FEC2_C7gd_xlarge <: FEC2_C7gd end
abstract type FEC2_C7gd_large <: FEC2_C7gd end
abstract type FEC2_C7gd_4xlarge <: FEC2_C7gd end
abstract type FEC2_C7gd_12xlarge <: FEC2_C7gd end
abstract type FEC2_C7gd_2xlarge <: FEC2_C7gd end
abstract type FEC2_C7gd_metal <: FEC2_C7gd end
abstract type FEC2_C7gd_16xlarge <: FEC2_C7gd end
abstract type FEC2_C7gd_8xlarge <: FEC2_C7gd end
abstract type FEC2_C7gd_medium <: FEC2_C7gd end

abstract type FEC2_C7gn_xlarge <: FEC2_C7gn end
abstract type FEC2_C7gn_large <: FEC2_C7gn end
abstract type FEC2_C7gn_metal <: FEC2_C7gn end
abstract type FEC2_C7gn_2xlarge <: FEC2_C7gn end
abstract type FEC2_C7gn_medium <: FEC2_C7gn end
abstract type FEC2_C7gn_16xlarge <: FEC2_C7gn end
abstract type FEC2_C7gn_12xlarge <: FEC2_C7gn end
abstract type FEC2_C7gn_8xlarge <: FEC2_C7gn end
abstract type FEC2_C7gn_4xlarge <: FEC2_C7gn end

abstract type FEC2_C7i_metal24xl <: FEC2_C7i end
abstract type FEC2_C7i_12xlarge <: FEC2_C7i end
abstract type FEC2_C7i_xlarge <: FEC2_C7i end
abstract type FEC2_C7i_8xlarge <: FEC2_C7i end
abstract type FEC2_C7i_2xlarge <: FEC2_C7i end
abstract type FEC2_C7i_16xlarge <: FEC2_C7i end
abstract type FEC2_C7i_48xlarge <: FEC2_C7i end
abstract type FEC2_C7i_4xlarge <: FEC2_C7i end
abstract type FEC2_C7i_24xlarge <: FEC2_C7i end
abstract type FEC2_C7i_metal48xl <: FEC2_C7i end
abstract type FEC2_C7i_large <: FEC2_C7i end

abstract type FEC2_Cc2_8xlarge <: FEC2_Cc2 end

abstract type FEC2_Cr1_8xlarge <: FEC2_Cr1 end

abstract type FEC2_D2_8xlarge <: FEC2_D2 end
abstract type FEC2_D2_4xlarge <: FEC2_D2 end
abstract type FEC2_D2_2xlarge <: FEC2_D2 end
abstract type FEC2_D2_xlarge <: FEC2_D2 end

abstract type FEC2_D3_xlarge <: FEC2_D3 end
abstract type FEC2_D3_2xlarge <: FEC2_D3 end
abstract type FEC2_D3_4xlarge <: FEC2_D3 end
abstract type FEC2_D3_8xlarge <: FEC2_D3 end

abstract type FEC2_D3en_12xlarge <: FEC2_D3en end
abstract type FEC2_D3en_8xlarge <: FEC2_D3en end
abstract type FEC2_D3en_xlarge <: FEC2_D3en end
abstract type FEC2_D3en_2xlarge <: FEC2_D3en end
abstract type FEC2_D3en_6xlarge <: FEC2_D3en end
abstract type FEC2_D3en_4xlarge <: FEC2_D3en end

abstract type FEC2_DL1_24xlarge <: FEC2_DL1 end

abstract type FEC2_F1_16xlarge <: FEC2_F1 end
abstract type FEC2_F1_4xlarge <: FEC2_F1 end
abstract type FEC2_F1_2xlarge <: FEC2_F1 end

abstract type FEC2_G2_8xlarge <: FEC2_G2 end
abstract type FEC2_G2_2xlarge <: FEC2_G2 end

abstract type FEC2_G3_16xlarge <: FEC2_G3 end
abstract type FEC2_G3_8xlarge <: FEC2_G3 end
abstract type FEC2_G3_4xlarge <: FEC2_G3 end

abstract type FEC2_G3s_xlarge <: FEC2_G3s end

abstract type FEC2_G4ad_xlarge <: FEC2_G4ad end
abstract type FEC2_G4ad_2xlarge <: FEC2_G4ad end
abstract type FEC2_G4ad_16xlarge <: FEC2_G4ad end
abstract type FEC2_G4ad_8xlarge <: FEC2_G4ad end
abstract type FEC2_G4ad_4xlarge <: FEC2_G4ad end

abstract type FEC2_G4dn_8xlarge <: FEC2_G4dn end
abstract type FEC2_G4dn_2xlarge <: FEC2_G4dn end
abstract type FEC2_G4dn_12xlarge <: FEC2_G4dn end
abstract type FEC2_G4dn_xlarge <: FEC2_G4dn end
abstract type FEC2_G4dn_16xlarge <: FEC2_G4dn end
abstract type FEC2_G4dn_metal <: FEC2_G4dn end
abstract type FEC2_G4dn_4xlarge <: FEC2_G4dn end

abstract type FEC2_G5_8xlarge <: FEC2_G5 end
abstract type FEC2_G5_48xlarge <: FEC2_G5 end
abstract type FEC2_G5_12xlarge <: FEC2_G5 end
abstract type FEC2_G5_4xlarge <: FEC2_G5 end
abstract type FEC2_G5_16xlarge <: FEC2_G5 end
abstract type FEC2_G5_24xlarge <: FEC2_G5 end
abstract type FEC2_G5_2xlarge <: FEC2_G5 end
abstract type FEC2_G5_xlarge <: FEC2_G5 end

abstract type FEC2_G5g_metal <: FEC2_G5g end
abstract type FEC2_G5g_16xlarge <: FEC2_G5g end
abstract type FEC2_G5g_2xlarge <: FEC2_G5g end
abstract type FEC2_G5g_4xlarge <: FEC2_G5g end
abstract type FEC2_G5g_xlarge <: FEC2_G5g end
abstract type FEC2_G5g_8xlarge <: FEC2_G5g end

abstract type FEC2_G6_xlarge <: FEC2_G6 end
abstract type FEC2_G6_4xlarge <: FEC2_G6 end
abstract type FEC2_G6_2xlarge <: FEC2_G6 end
abstract type FEC2_G6_24xlarge <: FEC2_G6 end
abstract type FEC2_G6_16xlarge <: FEC2_G6 end
abstract type FEC2_G6_8xlarge <: FEC2_G6 end
abstract type FEC2_G6_48xlarge <: FEC2_G6 end
abstract type FEC2_G6_12xlarge <: FEC2_G6 end

abstract type FEC2_Gr6_8xlarge <: FEC2_Gr6 end
abstract type FEC2_Gr6_4xlarge <: FEC2_Gr6 end

abstract type FEC2_H1_16xlarge <: FEC2_H1 end
abstract type FEC2_H1_8xlarge <: FEC2_H1 end
abstract type FEC2_H1_4xlarge <: FEC2_H1 end
abstract type FEC2_H1_2xlarge <: FEC2_H1 end

abstract type FEC2_Hpc6a_48xlarge <: FEC2_Hpc6a end

abstract type FEC2_Hpc6id_32xlarge <: FEC2_Hpc6id end

abstract type FEC2_Hpc7a_96xlarge <: FEC2_Hpc7a end
abstract type FEC2_Hpc7a_24xlarge <: FEC2_Hpc7a end
abstract type FEC2_Hpc7a_12xlarge <: FEC2_Hpc7a end
abstract type FEC2_Hpc7a_48xlarge <: FEC2_Hpc7a end

abstract type FEC2_Hpc7g_8xlarge <: FEC2_Hpc7g end
abstract type FEC2_Hpc7g_16xlarge <: FEC2_Hpc7g end
abstract type FEC2_Hpc7g_4xlarge <: FEC2_Hpc7g end

abstract type FEC2_Hs1_8xlarge <: FEC2_Hs1 end

abstract type FEC2_I2_8xlarge <: FEC2_I2 end
abstract type FEC2_I2_4xlarge <: FEC2_I2 end
abstract type FEC2_I2_2xlarge <: FEC2_I2 end
abstract type FEC2_I2_xlarge <: FEC2_I2 end
abstract type FEC2_I2_large <: FEC2_I2 end

abstract type FEC2_I3_metal <: FEC2_I3 end
abstract type FEC2_I3_16xlarge <: FEC2_I3 end
abstract type FEC2_I3_8xlarge <: FEC2_I3 end
abstract type FEC2_I3_4xlarge <: FEC2_I3 end
abstract type FEC2_I3_2xlarge <: FEC2_I3 end
abstract type FEC2_I3_xlarge <: FEC2_I3 end
abstract type FEC2_I3_large <: FEC2_I3 end

abstract type FEC2_I3en_24xlarge <: FEC2_I3en end
abstract type FEC2_I3en_12xlarge <: FEC2_I3en end
abstract type FEC2_I3en_2xlarge <: FEC2_I3en end
abstract type FEC2_I3en_large <: FEC2_I3en end
abstract type FEC2_I3en_6xlarge <: FEC2_I3en end
abstract type FEC2_I3en_xlarge <: FEC2_I3en end
abstract type FEC2_I3en_3xlarge <: FEC2_I3en end
abstract type FEC2_I3en_metal <: FEC2_I3en end

abstract type FEC2_I4g_4xlarge <: FEC2_I4g end
abstract type FEC2_I4g_large <: FEC2_I4g end
abstract type FEC2_I4g_xlarge <: FEC2_I4g end
abstract type FEC2_I4g_2xlarge <: FEC2_I4g end
abstract type FEC2_I4g_8xlarge <: FEC2_I4g end
abstract type FEC2_I4g_16xlarge <: FEC2_I4g end

abstract type FEC2_I4i_2xlarge <: FEC2_I4i end
abstract type FEC2_I4i_xlarge <: FEC2_I4i end
abstract type FEC2_I4i_12xlarge <: FEC2_I4i end
abstract type FEC2_I4i_4xlarge <: FEC2_I4i end
abstract type FEC2_I4i_metal <: FEC2_I4i end
abstract type FEC2_I4i_16xlarge <: FEC2_I4i end
abstract type FEC2_I4i_8xlarge <: FEC2_I4i end
abstract type FEC2_I4i_32xlarge <: FEC2_I4i end
abstract type FEC2_I4i_large <: FEC2_I4i end
abstract type FEC2_I4i_24xlarge <: FEC2_I4i end

abstract type FEC2_Im4gn_4xlarge <: FEC2_Im4gn end
abstract type FEC2_Im4gn_large <: FEC2_Im4gn end
abstract type FEC2_Im4gn_16xlarge <: FEC2_Im4gn end
abstract type FEC2_Im4gn_xlarge <: FEC2_Im4gn end
abstract type FEC2_Im4gn_2xlarge <: FEC2_Im4gn end
abstract type FEC2_Im4gn_8xlarge <: FEC2_Im4gn end

abstract type FEC2_Inf1_2xlarge <: FEC2_Inf1 end
abstract type FEC2_Inf1_xlarge <: FEC2_Inf1 end
abstract type FEC2_Inf1_6xlarge <: FEC2_Inf1 end
abstract type FEC2_Inf1_24xlarge <: FEC2_Inf1 end

abstract type FEC2_Inf2_8xlarge <: FEC2_Inf2 end

abstract type FEC2_Inf3_48xlarge <: FEC2_Inf3 end

abstract type FEC2_Inf4_24xlarge <: FEC2_Inf4 end

abstract type FEC2_Inf5_xlarge <: FEC2_Inf5 end

abstract type FEC2_Is4gen_8xlarge <: FEC2_Is4gen end
abstract type FEC2_Is4gen_large <: FEC2_Is4gen end
abstract type FEC2_Is4gen_4xlarge <: FEC2_Is4gen end
abstract type FEC2_Is4gen_xlarge <: FEC2_Is4gen end
abstract type FEC2_Is4gen_2xlarge <: FEC2_Is4gen end
abstract type FEC2_Is4gen_medium <: FEC2_Is4gen end

abstract type FEC2_M1_xlarge <: FEC2_M1 end
abstract type FEC2_M1_large <: FEC2_M1 end
abstract type FEC2_M1_medium <: FEC2_M1 end
abstract type FEC2_M1_small <: FEC2_M1 end

abstract type FEC2_M2_4xlarge <: FEC2_M2 end
abstract type FEC2_M2_2xlarge <: FEC2_M2 end
abstract type FEC2_M2_xlarge <: FEC2_M2 end

abstract type FEC2_M3_2xlarge <: FEC2_M3 end
abstract type FEC2_M3_xlarge <: FEC2_M3 end
abstract type FEC2_M3_large <: FEC2_M3 end
abstract type FEC2_M3_medium <: FEC2_M3 end

abstract type FEC2_M4_16xlarge <: FEC2_M4 end
abstract type FEC2_M4_10xlarge <: FEC2_M4 end
abstract type FEC2_M4_4xlarge <: FEC2_M4 end
abstract type FEC2_M4_2xlarge <: FEC2_M4 end
abstract type FEC2_M4_xlarge <: FEC2_M4 end
abstract type FEC2_M4_large <: FEC2_M4 end

abstract type FEC2_M5_metal <: FEC2_M5 end
abstract type FEC2_M5_24xlarge <: FEC2_M5 end
abstract type FEC2_M5_16xlarge <: FEC2_M5 end
abstract type FEC2_M5_12xlarge <: FEC2_M5 end
abstract type FEC2_M5_8xlarge <: FEC2_M5 end
abstract type FEC2_M5_4xlarge <: FEC2_M5 end
abstract type FEC2_M5_2xlarge <: FEC2_M5 end
abstract type FEC2_M5_xlarge <: FEC2_M5 end
abstract type FEC2_M5_large <: FEC2_M5 end

abstract type FEC2_M5a_xlarge <: FEC2_M5a end
abstract type FEC2_M5a_16xlarge <: FEC2_M5a end
abstract type FEC2_M5a_8xlarge <: FEC2_M5a end
abstract type FEC2_M5a_large <: FEC2_M5a end
abstract type FEC2_M5a_24xlarge <: FEC2_M5a end
abstract type FEC2_M5a_2xlarge <: FEC2_M5a end
abstract type FEC2_M5a_12xlarge <: FEC2_M5a end
abstract type FEC2_M5a_4xlarge <: FEC2_M5a end

abstract type FEC2_M5ad_16xlarge <: FEC2_M5ad end
abstract type FEC2_M5ad_8xlarge <: FEC2_M5ad end
abstract type FEC2_M5ad_large <: FEC2_M5ad end
abstract type FEC2_M5ad_xlarge <: FEC2_M5ad end
abstract type FEC2_M5ad_24xlarge <: FEC2_M5ad end
abstract type FEC2_M5ad_2xlarge <: FEC2_M5ad end
abstract type FEC2_M5ad_4xlarge <: FEC2_M5ad end
abstract type FEC2_M5ad_12xlarge <: FEC2_M5ad end

abstract type FEC2_M5d_metal <: FEC2_M5d end
abstract type FEC2_M5d_24xlarge <: FEC2_M5d end
abstract type FEC2_M5d_16xlarge <: FEC2_M5d end
abstract type FEC2_M5d_12xlarge <: FEC2_M5d end
abstract type FEC2_M5d_8xlarge <: FEC2_M5d end
abstract type FEC2_M5d_4xlarge <: FEC2_M5d end
abstract type FEC2_M5d_2xlarge <: FEC2_M5d end
abstract type FEC2_M5d_xlarge <: FEC2_M5d end
abstract type FEC2_M5d_large <: FEC2_M5d end

abstract type FEC2_M5dn_24xlarge <: FEC2_M5dn end
abstract type FEC2_M5dn_16xlarge <: FEC2_M5dn end
abstract type FEC2_M5dn_8xlarge <: FEC2_M5dn end
abstract type FEC2_M5dn_12xlarge <: FEC2_M5dn end
abstract type FEC2_M5dn_2xlarge <: FEC2_M5dn end
abstract type FEC2_M5dn_xlarge <: FEC2_M5dn end
abstract type FEC2_M5dn_4xlarge <: FEC2_M5dn end
abstract type FEC2_M5dn_metal <: FEC2_M5dn end
abstract type FEC2_M5dn_large <: FEC2_M5dn end

abstract type FEC2_M5n_12xlarge <: FEC2_M5n end
abstract type FEC2_M5n_large <: FEC2_M5n end
abstract type FEC2_M5n_16xlarge <: FEC2_M5n end
abstract type FEC2_M5n_24xlarge <: FEC2_M5n end
abstract type FEC2_M5n_2xlarge <: FEC2_M5n end
abstract type FEC2_M5n_metal <: FEC2_M5n end
abstract type FEC2_M5n_xlarge <: FEC2_M5n end
abstract type FEC2_M5n_8xlarge <: FEC2_M5n end
abstract type FEC2_M5n_4xlarge <: FEC2_M5n end

abstract type FEC2_M5zn_3xlarge <: FEC2_M5zn end
abstract type FEC2_M5zn_metal <: FEC2_M5zn end
abstract type FEC2_M5zn_6xlarge <: FEC2_M5zn end
abstract type FEC2_M5zn_large <: FEC2_M5zn end
abstract type FEC2_M5zn_12xlarge <: FEC2_M5zn end
abstract type FEC2_M5zn_2xlarge <: FEC2_M5zn end
abstract type FEC2_M5zn_xlarge <: FEC2_M5zn end

abstract type FEC2_M6a_24xlarge <: FEC2_M6a end
abstract type FEC2_M6a_2xlarge <: FEC2_M6a end
abstract type FEC2_M6a_large <: FEC2_M6a end
abstract type FEC2_M6a_8xlarge <: FEC2_M6a end
abstract type FEC2_M6a_48xlarge <: FEC2_M6a end
abstract type FEC2_M6a_xlarge <: FEC2_M6a end
abstract type FEC2_M6a_32xlarge <: FEC2_M6a end
abstract type FEC2_M6a_16xlarge <: FEC2_M6a end
abstract type FEC2_M6a_12xlarge <: FEC2_M6a end
abstract type FEC2_M6a_4xlarge <: FEC2_M6a end
abstract type FEC2_M6a_metal <: FEC2_M6a end

abstract type FEC2_M6g_large <: FEC2_M6g end
abstract type FEC2_M6g_xlarge <: FEC2_M6g end
abstract type FEC2_M6g_2xlarge <: FEC2_M6g end
abstract type FEC2_M6g_4xlarge <: FEC2_M6g end
abstract type FEC2_M6g_medium <: FEC2_M6g end
abstract type FEC2_M6g_12xlarge <: FEC2_M6g end
abstract type FEC2_M6g_8xlarge <: FEC2_M6g end
abstract type FEC2_M6g_metal <: FEC2_M6g end
abstract type FEC2_M6g_16xlarge <: FEC2_M6g end

abstract type FEC2_M6gd_xlarge <: FEC2_M6gd end
abstract type FEC2_M6gd_medium <: FEC2_M6gd end
abstract type FEC2_M6gd_16xlarge <: FEC2_M6gd end
abstract type FEC2_M6gd_12xlarge <: FEC2_M6gd end
abstract type FEC2_M6gd_4xlarge <: FEC2_M6gd end
abstract type FEC2_M6gd_metal <: FEC2_M6gd end
abstract type FEC2_M6gd_8xlarge <: FEC2_M6gd end
abstract type FEC2_M6gd_2xlarge <: FEC2_M6gd end
abstract type FEC2_M6gd_large <: FEC2_M6gd end

abstract type FEC2_M6i_8xlarge <: FEC2_M6i end
abstract type FEC2_M6i_12xlarge <: FEC2_M6i end
abstract type FEC2_M6i_2xlarge <: FEC2_M6i end
abstract type FEC2_M6i_large <: FEC2_M6i end
abstract type FEC2_M6i_32xlarge <: FEC2_M6i end
abstract type FEC2_M6i_16xlarge <: FEC2_M6i end
abstract type FEC2_M6i_24xlarge <: FEC2_M6i end
abstract type FEC2_M6i_xlarge <: FEC2_M6i end
abstract type FEC2_M6i_metal <: FEC2_M6i end
abstract type FEC2_M6i_4xlarge <: FEC2_M6i end

abstract type FEC2_M6id_2xlarge <: FEC2_M6id end
abstract type FEC2_M6id_32xlarge <: FEC2_M6id end
abstract type FEC2_M6id_12xlarge <: FEC2_M6id end
abstract type FEC2_M6id_16xlarge <: FEC2_M6id end
abstract type FEC2_M6id_xlarge <: FEC2_M6id end
abstract type FEC2_M6id_metal <: FEC2_M6id end
abstract type FEC2_M6id_24xlarge <: FEC2_M6id end
abstract type FEC2_M6id_8xlarge <: FEC2_M6id end
abstract type FEC2_M6id_large <: FEC2_M6id end
abstract type FEC2_M6id_4xlarge <: FEC2_M6id end

abstract type FEC2_M6idn_metal <: FEC2_M6idn end
abstract type FEC2_M6idn_xlarge <: FEC2_M6idn end
abstract type FEC2_M6idn_24xlarge <: FEC2_M6idn end
abstract type FEC2_M6idn_2xlarge <: FEC2_M6idn end
abstract type FEC2_M6idn_32xlarge <: FEC2_M6idn end
abstract type FEC2_M6idn_4xlarge <: FEC2_M6idn end
abstract type FEC2_M6idn_12xlarge <: FEC2_M6idn end
abstract type FEC2_M6idn_large <: FEC2_M6idn end
abstract type FEC2_M6idn_16xlarge <: FEC2_M6idn end
abstract type FEC2_M6idn_8xlarge <: FEC2_M6idn end

abstract type FEC2_M6in_xlarge <: FEC2_M6in end
abstract type FEC2_M6in_metal <: FEC2_M6in end
abstract type FEC2_M6in_16xlarge <: FEC2_M6in end
abstract type FEC2_M6in_32xlarge <: FEC2_M6in end
abstract type FEC2_M6in_12xlarge <: FEC2_M6in end
abstract type FEC2_M6in_large <: FEC2_M6in end
abstract type FEC2_M6in_2xlarge <: FEC2_M6in end
abstract type FEC2_M6in_8xlarge <: FEC2_M6in end
abstract type FEC2_M6in_24xlarge <: FEC2_M6in end
abstract type FEC2_M6in_4xlarge <: FEC2_M6in end

abstract type FEC2_M7a_8xlarge <: FEC2_M7a end
abstract type FEC2_M7a_xlarge <: FEC2_M7a end
abstract type FEC2_M7a_16xlarge <: FEC2_M7a end
abstract type FEC2_M7a_12xlarge <: FEC2_M7a end
abstract type FEC2_M7a_32xlarge <: FEC2_M7a end
abstract type FEC2_M7a_48xlarge <: FEC2_M7a end
abstract type FEC2_M7a_metal48xl <: FEC2_M7a end
abstract type FEC2_M7a_large <: FEC2_M7a end
abstract type FEC2_M7a_4xlarge <: FEC2_M7a end
abstract type FEC2_M7a_2xlarge <: FEC2_M7a end
abstract type FEC2_M7a_medium <: FEC2_M7a end
abstract type FEC2_M7a_24xlarge <: FEC2_M7a end

abstract type FEC2_M7g_metal <: FEC2_M7g end
abstract type FEC2_M7g_medium <: FEC2_M7g end
abstract type FEC2_M7g_xlarge <: FEC2_M7g end
abstract type FEC2_M7g_4xlarge <: FEC2_M7g end
abstract type FEC2_M7g_16xlarge <: FEC2_M7g end
abstract type FEC2_M7g_large <: FEC2_M7g end
abstract type FEC2_M7g_8xlarge <: FEC2_M7g end
abstract type FEC2_M7g_2xlarge <: FEC2_M7g end
abstract type FEC2_M7g_12xlarge <: FEC2_M7g end

abstract type FEC2_M7gd_16xlarge <: FEC2_M7gd end
abstract type FEC2_M7gd_medium <: FEC2_M7gd end
abstract type FEC2_M7gd_large <: FEC2_M7gd end
abstract type FEC2_M7gd_metal <: FEC2_M7gd end
abstract type FEC2_M7gd_2xlarge <: FEC2_M7gd end
abstract type FEC2_M7gd_xlarge <: FEC2_M7gd end
abstract type FEC2_M7gd_12xlarge <: FEC2_M7gd end
abstract type FEC2_M7gd_8xlarge <: FEC2_M7gd end
abstract type FEC2_M7gd_4xlarge <: FEC2_M7gd end

abstract type FEC2_M7i_16xlarge <: FEC2_M7i end
abstract type FEC2_M7i_xlarge <: FEC2_M7i end
abstract type FEC2_M7i_metal48xl <: FEC2_M7i end
abstract type FEC2_M7i_large <: FEC2_M7i end
abstract type FEC2_M7i_8xlarge <: FEC2_M7i end
abstract type FEC2_M7i_48xlarge <: FEC2_M7i end
abstract type FEC2_M7i_4xlarge <: FEC2_M7i end
abstract type FEC2_M7i_metal24xl <: FEC2_M7i end
abstract type FEC2_M7i_24xlarge <: FEC2_M7i end
abstract type FEC2_M7i_2xlarge <: FEC2_M7i end
abstract type FEC2_M7i_12xlarge <: FEC2_M7i end
abstract type FEC2_M7iflex_8xlarge <: FEC2_M7iflex end
abstract type FEC2_M7iflex_xlarge <: FEC2_M7iflex end
abstract type FEC2_M7iflex_large <: FEC2_M7iflex end
abstract type FEC2_M7iflex_2xlarge <: FEC2_M7iflex end
abstract type FEC2_M7iflex_4xlarge <: FEC2_M7iflex end

abstract type FEC2_Mac1_metal <: FEC2_Mac1 end

abstract type FEC2_Mac2_metal <: FEC2_Mac2 end

abstract type FEC2_Mac2m2_metal <: FEC2_Mac2m2 end

abstract type FEC2_Mac2m2pro_metal <: FEC2_Mac2m2pro end

abstract type FEC2_P2_16xlarge <: FEC2_P2 end
abstract type FEC2_P2_8xlarge <: FEC2_P2 end
abstract type FEC2_P2_xlarge <: FEC2_P2 end

abstract type FEC2_P3_16xlarge <: FEC2_P3 end
abstract type FEC2_P3_8xlarge <: FEC2_P3 end
abstract type FEC2_P3_2xlarge <: FEC2_P3 end

abstract type FEC2_P3dn_24xlarge <: FEC2_P3dn end

abstract type FEC2_P4d_24xlarge <: FEC2_P4d end

abstract type FEC2_P4de_24xlarge <: FEC2_P4de end

abstract type FEC2_P5_48xlarge <: FEC2_P5 end

abstract type FEC2_R3_8xlarge <: FEC2_R3 end
abstract type FEC2_R3_4xlarge <: FEC2_R3 end
abstract type FEC2_R3_2xlarge <: FEC2_R3 end
abstract type FEC2_R3_xlarge <: FEC2_R3 end
abstract type FEC2_R3_large <: FEC2_R3 end

abstract type FEC2_R4_16xlarge <: FEC2_R4 end
abstract type FEC2_R4_8xlarge <: FEC2_R4 end
abstract type FEC2_R4_4xlarge <: FEC2_R4 end
abstract type FEC2_R4_2xlarge <: FEC2_R4 end
abstract type FEC2_R4_xlarge <: FEC2_R4 end
abstract type FEC2_R4_large <: FEC2_R4 end

abstract type FEC2_R5_metal <: FEC2_R5 end
abstract type FEC2_R5_24xlarge <: FEC2_R5 end
abstract type FEC2_R5_16xlarge <: FEC2_R5 end
abstract type FEC2_R5_12xlarge <: FEC2_R5 end
abstract type FEC2_R5_8xlarge <: FEC2_R5 end
abstract type FEC2_R5_4xlarge <: FEC2_R5 end
abstract type FEC2_R5_2xlarge <: FEC2_R5 end
abstract type FEC2_R5_xlarge <: FEC2_R5 end
abstract type FEC2_R5_large <: FEC2_R5 end

abstract type FEC2_R5a_8xlarge <: FEC2_R5a end
abstract type FEC2_R5a_xlarge <: FEC2_R5a end
abstract type FEC2_R5a_24xlarge <: FEC2_R5a end
abstract type FEC2_R5a_large <: FEC2_R5a end
abstract type FEC2_R5a_16xlarge <: FEC2_R5a end
abstract type FEC2_R5a_4xlarge <: FEC2_R5a end
abstract type FEC2_R5a_2xlarge <: FEC2_R5a end
abstract type FEC2_R5a_12xlarge <: FEC2_R5a end

abstract type FEC2_R5ad_4xlarge <: FEC2_R5ad end
abstract type FEC2_R5ad_2xlarge <: FEC2_R5ad end
abstract type FEC2_R5ad_16xlarge <: FEC2_R5ad end
abstract type FEC2_R5ad_24xlarge <: FEC2_R5ad end
abstract type FEC2_R5ad_xlarge <: FEC2_R5ad end
abstract type FEC2_R5ad_8xlarge <: FEC2_R5ad end
abstract type FEC2_R5ad_large <: FEC2_R5ad end
abstract type FEC2_R5ad_12xlarge <: FEC2_R5ad end

abstract type FEC2_R5b_12xlarge <: FEC2_R5b end
abstract type FEC2_R5b_large <: FEC2_R5b end
abstract type FEC2_R5b_8xlarge <: FEC2_R5b end
abstract type FEC2_R5b_2xlarge <: FEC2_R5b end
abstract type FEC2_R5b_metal <: FEC2_R5b end
abstract type FEC2_R5b_4xlarge <: FEC2_R5b end
abstract type FEC2_R5b_24xlarge <: FEC2_R5b end
abstract type FEC2_R5b_16xlarge <: FEC2_R5b end
abstract type FEC2_R5b_xlarge <: FEC2_R5b end

abstract type FEC2_R5d_metal <: FEC2_R5d end
abstract type FEC2_R5d_24xlarge <: FEC2_R5d end
abstract type FEC2_R5d_16xlarge <: FEC2_R5d end
abstract type FEC2_R5d_12xlarge <: FEC2_R5d end
abstract type FEC2_R5d_8xlarge <: FEC2_R5d end
abstract type FEC2_R5d_4xlarge <: FEC2_R5d end
abstract type FEC2_R5d_2xlarge <: FEC2_R5d end
abstract type FEC2_R5d_xlarge <: FEC2_R5d end
abstract type FEC2_R5d_large <: FEC2_R5d end

abstract type FEC2_R5dn_8xlarge <: FEC2_R5dn end
abstract type FEC2_R5dn_large <: FEC2_R5dn end
abstract type FEC2_R5dn_xlarge <: FEC2_R5dn end
abstract type FEC2_R5dn_16xlarge <: FEC2_R5dn end
abstract type FEC2_R5dn_12xlarge <: FEC2_R5dn end
abstract type FEC2_R5dn_24xlarge <: FEC2_R5dn end
abstract type FEC2_R5dn_2xlarge <: FEC2_R5dn end
abstract type FEC2_R5dn_metal <: FEC2_R5dn end
abstract type FEC2_R5dn_4xlarge <: FEC2_R5dn end

abstract type FEC2_R5n_metal <: FEC2_R5n end
abstract type FEC2_R5n_large <: FEC2_R5n end
abstract type FEC2_R5n_xlarge <: FEC2_R5n end
abstract type FEC2_R5n_8xlarge <: FEC2_R5n end
abstract type FEC2_R5n_16xlarge <: FEC2_R5n end
abstract type FEC2_R5n_2xlarge <: FEC2_R5n end
abstract type FEC2_R5n_12xlarge <: FEC2_R5n end
abstract type FEC2_R5n_24xlarge <: FEC2_R5n end
abstract type FEC2_R5n_4xlarge <: FEC2_R5n end

abstract type FEC2_R6a_24xlarge <: FEC2_R6a end
abstract type FEC2_R6a_4xlarge <: FEC2_R6a end
abstract type FEC2_R6a_2xlarge <: FEC2_R6a end
abstract type FEC2_R6a_xlarge <: FEC2_R6a end
abstract type FEC2_R6a_32xlarge <: FEC2_R6a end
abstract type FEC2_R6a_large <: FEC2_R6a end
abstract type FEC2_R6a_16xlarge <: FEC2_R6a end
abstract type FEC2_R6a_12xlarge <: FEC2_R6a end
abstract type FEC2_R6a_48xlarge <: FEC2_R6a end
abstract type FEC2_R6a_8xlarge <: FEC2_R6a end
abstract type FEC2_R6a_metal <: FEC2_R6a end

abstract type FEC2_R6g_medium <: FEC2_R6g end
abstract type FEC2_R6g_16xlarge <: FEC2_R6g end
abstract type FEC2_R6g_xlarge <: FEC2_R6g end
abstract type FEC2_R6g_4xlarge <: FEC2_R6g end
abstract type FEC2_R6g_large <: FEC2_R6g end
abstract type FEC2_R6g_8xlarge <: FEC2_R6g end
abstract type FEC2_R6g_2xlarge <: FEC2_R6g end
abstract type FEC2_R6g_metal <: FEC2_R6g end
abstract type FEC2_R6g_12xlarge <: FEC2_R6g end

abstract type FEC2_R6gd_4xlarge <: FEC2_R6gd end
abstract type FEC2_R6gd_12xlarge <: FEC2_R6gd end
abstract type FEC2_R6gd_8xlarge <: FEC2_R6gd end
abstract type FEC2_R6gd_2xlarge <: FEC2_R6gd end
abstract type FEC2_R6gd_xlarge <: FEC2_R6gd end
abstract type FEC2_R6gd_16xlarge <: FEC2_R6gd end
abstract type FEC2_R6gd_large <: FEC2_R6gd end
abstract type FEC2_R6gd_metal <: FEC2_R6gd end
abstract type FEC2_R6gd_medium <: FEC2_R6gd end

abstract type FEC2_R6i_2xlarge <: FEC2_R6i end
abstract type FEC2_R6i_metal <: FEC2_R6i end
abstract type FEC2_R6i_large <: FEC2_R6i end
abstract type FEC2_R6i_xlarge <: FEC2_R6i end
abstract type FEC2_R6i_24xlarge <: FEC2_R6i end
abstract type FEC2_R6i_12xlarge <: FEC2_R6i end
abstract type FEC2_R6i_8xlarge <: FEC2_R6i end
abstract type FEC2_R6i_16xlarge <: FEC2_R6i end
abstract type FEC2_R6i_4xlarge <: FEC2_R6i end
abstract type FEC2_R6i_32xlarge <: FEC2_R6i end

abstract type FEC2_R6id_8xlarge <: FEC2_R6id end
abstract type FEC2_R6id_16xlarge <: FEC2_R6id end
abstract type FEC2_R6id_32xlarge <: FEC2_R6id end
abstract type FEC2_R6id_metal <: FEC2_R6id end
abstract type FEC2_R6id_2xlarge <: FEC2_R6id end
abstract type FEC2_R6id_24xlarge <: FEC2_R6id end
abstract type FEC2_R6id_4xlarge <: FEC2_R6id end
abstract type FEC2_R6id_large <: FEC2_R6id end
abstract type FEC2_R6id_xlarge <: FEC2_R6id end
abstract type FEC2_R6id_12xlarge <: FEC2_R6id end

abstract type FEC2_R6idn_12xlarge <: FEC2_R6idn end
abstract type FEC2_R6idn_metal <: FEC2_R6idn end
abstract type FEC2_R6idn_8xlarge <: FEC2_R6idn end
abstract type FEC2_R6idn_4xlarge <: FEC2_R6idn end
abstract type FEC2_R6idn_16xlarge <: FEC2_R6idn end
abstract type FEC2_R6idn_32xlarge <: FEC2_R6idn end
abstract type FEC2_R6idn_24xlarge <: FEC2_R6idn end
abstract type FEC2_R6idn_large <: FEC2_R6idn end
abstract type FEC2_R6idn_2xlarge <: FEC2_R6idn end
abstract type FEC2_R6idn_xlarge <: FEC2_R6idn end

abstract type FEC2_R6in_metal <: FEC2_R6in end
abstract type FEC2_R6in_24xlarge <: FEC2_R6in end
abstract type FEC2_R6in_4xlarge <: FEC2_R6in end
abstract type FEC2_R6in_12xlarge <: FEC2_R6in end
abstract type FEC2_R6in_16xlarge <: FEC2_R6in end
abstract type FEC2_R6in_2xlarge <: FEC2_R6in end
abstract type FEC2_R6in_32xlarge <: FEC2_R6in end
abstract type FEC2_R6in_8xlarge <: FEC2_R6in end
abstract type FEC2_R6in_xlarge <: FEC2_R6in end
abstract type FEC2_R6in_large <: FEC2_R6in end

abstract type FEC2_R7a_12xlarge <: FEC2_R7a end
abstract type FEC2_R7a_medium <: FEC2_R7a end
abstract type FEC2_R7a_2xlarge <: FEC2_R7a end
abstract type FEC2_R7a_8xlarge <: FEC2_R7a end
abstract type FEC2_R7a_16xlarge <: FEC2_R7a end
abstract type FEC2_R7a_xlarge <: FEC2_R7a end
abstract type FEC2_R7a_4xlarge <: FEC2_R7a end
abstract type FEC2_R7a_48xlarge <: FEC2_R7a end
abstract type FEC2_R7a_24xlarge <: FEC2_R7a end
abstract type FEC2_R7a_metal48xl <: FEC2_R7a end
abstract type FEC2_R7a_large <: FEC2_R7a end
abstract type FEC2_R7a_32xlarge <: FEC2_R7a end

abstract type FEC2_R7g_xlarge <: FEC2_R7g end
abstract type FEC2_R7g_4xlarge <: FEC2_R7g end
abstract type FEC2_R7g_metal <: FEC2_R7g end
abstract type FEC2_R7g_medium <: FEC2_R7g end
abstract type FEC2_R7g_16xlarge <: FEC2_R7g end
abstract type FEC2_R7g_12xlarge <: FEC2_R7g end
abstract type FEC2_R7g_large <: FEC2_R7g end
abstract type FEC2_R7g_8xlarge <: FEC2_R7g end
abstract type FEC2_R7g_2xlarge <: FEC2_R7g end

abstract type FEC2_R7gd_metal <: FEC2_R7gd end
abstract type FEC2_R7gd_large <: FEC2_R7gd end
abstract type FEC2_R7gd_2xlarge <: FEC2_R7gd end
abstract type FEC2_R7gd_16xlarge <: FEC2_R7gd end
abstract type FEC2_R7gd_12xlarge <: FEC2_R7gd end
abstract type FEC2_R7gd_4xlarge <: FEC2_R7gd end
abstract type FEC2_R7gd_xlarge <: FEC2_R7gd end
abstract type FEC2_R7gd_medium <: FEC2_R7gd end
abstract type FEC2_R7gd_8xlarge <: FEC2_R7gd end

abstract type FEC2_R7i_xlarge <: FEC2_R7i end
abstract type FEC2_R7i_16xlarge <: FEC2_R7i end
abstract type FEC2_R7i_metal24xl <: FEC2_R7i end
abstract type FEC2_R7i_8xlarge <: FEC2_R7i end
abstract type FEC2_R7i_48xlarge <: FEC2_R7i end
abstract type FEC2_R7i_4xlarge <: FEC2_R7i end
abstract type FEC2_R7i_large <: FEC2_R7i end
abstract type FEC2_R7i_metal48xl <: FEC2_R7i end
abstract type FEC2_R7i_2xlarge <: FEC2_R7i end
abstract type FEC2_R7i_12xlarge <: FEC2_R7i end
abstract type FEC2_R7i_24xlarge <: FEC2_R7i end

abstract type FEC2_R7iz_8xlarge <: FEC2_R7iz end
abstract type FEC2_R7iz_12xlarge <: FEC2_R7iz end
abstract type FEC2_R7iz_16xlarge <: FEC2_R7iz end
abstract type FEC2_R7iz_xlarge <: FEC2_R7iz end
abstract type FEC2_R7iz_4xlarge <: FEC2_R7iz end
abstract type FEC2_R7iz_32xlarge <: FEC2_R7iz end
abstract type FEC2_R7iz_2xlarge <: FEC2_R7iz end
abstract type FEC2_R7iz_large <: FEC2_R7iz end
abstract type FEC2_R7iz_metal32xl <: FEC2_R7iz end
abstract type FEC2_R7iz_metal16xl <: FEC2_R7iz end

abstract type FEC2_T1_micro <: FEC2_T1 end

abstract type FEC2_T2_2xlarge <: FEC2_T2 end
abstract type FEC2_T2_xlarge <: FEC2_T2 end
abstract type FEC2_T2_large <: FEC2_T2 end
abstract type FEC2_T2_medium <: FEC2_T2 end
abstract type FEC2_T2_small <: FEC2_T2 end
abstract type FEC2_T2_micro <: FEC2_T2 end
abstract type FEC2_T2_nano <: FEC2_T2 end

abstract type FEC2_T3_2xlarge <: FEC2_T3 end
abstract type FEC2_T3_xlarge <: FEC2_T3 end
abstract type FEC2_T3_large <: FEC2_T3 end
abstract type FEC2_T3_small <: FEC2_T3 end
abstract type FEC2_T3_medium <: FEC2_T3 end
abstract type FEC2_T3_micro <: FEC2_T3 end
abstract type FEC2_T3_nano <: FEC2_T3 end

abstract type FEC2_T3a_2xlarge <: FEC2_T3a end
abstract type FEC2_T3a_xlarge <: FEC2_T3a end
abstract type FEC2_T3a_large <: FEC2_T3a end
abstract type FEC2_T3a_small <: FEC2_T3a end
abstract type FEC2_T3a_medium <: FEC2_T3a end
abstract type FEC2_T3a_micro <: FEC2_T3a end
abstract type FEC2_T3a_nano <: FEC2_T3a end

abstract type FEC2_T4g_large <: FEC2_T4g end
abstract type FEC2_T4g_micro <: FEC2_T4g end
abstract type FEC2_T4g_medium <: FEC2_T4g end
abstract type FEC2_T4g_small <: FEC2_T4g end
abstract type FEC2_T4g_2xlarge <: FEC2_T4g end
abstract type FEC2_T4g_nano <: FEC2_T4g end
abstract type FEC2_T4g_xlarge <: FEC2_T4g end

abstract type FEC2_Trn1_32xlarge <: FEC2_Trn1 end
abstract type FEC2_Trn1_2xlarge <: FEC2_Trn1 end

abstract type FEC2_Trn1n_32xlarge <: FEC2_Trn1n end

abstract type FEC2_U12tb1_112xlarge <: FEC2_U12tb1 end
abstract type FEC2_U12tb1_metal <: FEC2_U12tb1 end

abstract type FEC2_U18tb1_112xlarge <: FEC2_U18tb1 end
abstract type FEC2_U18tb1_metal <: FEC2_U18tb1 end

abstract type FEC2_U24tb1_112xlarge <: FEC2_U24tb1 end
abstract type FEC2_U24tb1_metal <: FEC2_U24tb1 end

abstract type FEC2_U3tb1_56xlarge <: FEC2_U3tb1 end

abstract type FEC2_U6tb1_112xlarge <: FEC2_U6tb1 end
abstract type FEC2_U6tb1_56xlarge <: FEC2_U6tb1 end
abstract type FEC2_U6tb1_metal <: FEC2_U6tb1 end

abstract type FEC2_U9tb1_112xlarge <: FEC2_U9tb1 end
abstract type FEC2_U9tb1_metal <: FEC2_U9tb1 end

abstract type FEC2_VT1_24xlarge <: FEC2_VT1 end
abstract type FEC2_VT1_3xlarge <: FEC2_VT1 end
abstract type FEC2_VT1_6xlarge <: FEC2_VT1 end

abstract type FEC2_X1_32xlarge <: FEC2_X1 end
abstract type FEC2_X1_16xlarge <: FEC2_X1 end

abstract type FEC2_X1e_32xlarge <: FEC2_X1e end
abstract type FEC2_X1e_16xlarge <: FEC2_X1e end
abstract type FEC2_X1e_8xlarge <: FEC2_X1e end
abstract type FEC2_X1e_4xlarge <: FEC2_X1e end
abstract type FEC2_X1e_2xlarge <: FEC2_X1e end
abstract type FEC2_X1e_xlarge <: FEC2_X1e end

abstract type FEC2_X2gd_metal <: FEC2_X2gd end
abstract type FEC2_X2gd_2xlarge <: FEC2_X2gd end
abstract type FEC2_X2gd_large <: FEC2_X2gd end
abstract type FEC2_X2gd_8xlarge <: FEC2_X2gd end
abstract type FEC2_X2gd_16xlarge <: FEC2_X2gd end
abstract type FEC2_X2gd_xlarge <: FEC2_X2gd end
abstract type FEC2_X2gd_12xlarge <: FEC2_X2gd end
abstract type FEC2_X2gd_medium <: FEC2_X2gd end
abstract type FEC2_X2gd_4xlarge <: FEC2_X2gd end

abstract type FEC2_X2idn_metal <: FEC2_X2idn end
abstract type FEC2_X2idn_16xlarge <: FEC2_X2idn end
abstract type FEC2_X2idn_24xlarge <: FEC2_X2idn end
abstract type FEC2_X2idn_32xlarge <: FEC2_X2idn end

abstract type FEC2_X2iedn_32xlarge <: FEC2_X2iedn end
abstract type FEC2_X2iedn_16xlarge <: FEC2_X2iedn end
abstract type FEC2_X2iedn_24xlarge <: FEC2_X2iedn end
abstract type FEC2_X2iedn_xlarge <: FEC2_X2iedn end
abstract type FEC2_X2iedn_metal <: FEC2_X2iedn end
abstract type FEC2_X2iedn_2xlarge <: FEC2_X2iedn end
abstract type FEC2_X2iedn_4xlarge <: FEC2_X2iedn end
abstract type FEC2_X2iedn_8xlarge <: FEC2_X2iedn end

abstract type FEC2_X2iezn_12xlarge <: FEC2_X2iezn end
abstract type FEC2_X2iezn_6xlarge <: FEC2_X2iezn end
abstract type FEC2_X2iezn_2xlarge <: FEC2_X2iezn end
abstract type FEC2_X2iezn_4xlarge <: FEC2_X2iezn end
abstract type FEC2_X2iezn_metal <: FEC2_X2iezn end
abstract type FEC2_X2iezn_8xlarge <: FEC2_X2iezn end

abstract type FEC2_z1d_metal <: FEC2_z1d end
abstract type FEC2_z1d_12xlarge <: FEC2_z1d end
abstract type FEC2_z1d_6xlarge <: FEC2_z1d end
abstract type FEC2_z1d_3xlarge <: FEC2_z1d end
abstract type FEC2_z1d_2xlarge <: FEC2_z1d end
abstract type FEC2_z1d_xlarge <: FEC2_z1d end
abstract type FEC2_z1d_large <: FEC2_z1d end
