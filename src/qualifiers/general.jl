abstract type PlatformType end

abstract type QuantifierFeature <: PlatformType end
abstract type QualifierFeature <: PlatformType end

# Accelerator Types

abstract type AcceleratorType <: QualifierFeature end
abstract type GPU <: AcceleratorType end
abstract type FPGA <: AcceleratorType end
abstract type MIC <: AcceleratorType end

abstract type Google_TPU <: GPU end
abstract type NVIDIA_TensorCore <: GPU end

# NVIDIA Architectures

abstract type AcceleratorArch <: QualifierFeature end
abstract type NVIDIA_Architecture <: AcceleratorArch end

abstract type NVIDIA_Farenheit <: NVIDIA_Architecture end
abstract type NVIDIA_Celsius <: NVIDIA_Farenheit end
abstract type NVIDIA_Kelvin <: NVIDIA_Celsius end
abstract type NVIDIA_Rankine <: NVIDIA_Kelvin end
abstract type NVIDIA_Curie <: NVIDIA_Rankine end
abstract type NVIDIA_Tesla <: NVIDIA_Curie end
abstract type NVIDIA_Tesla2 <: NVIDIA_Tesla end
abstract type NVIDIA_Fermi <: NVIDIA_Tesla2 end
abstract type NVIDIA_Kepler <: NVIDIA_Fermi end
abstract type NVIDIA_Kepler2 <: NVIDIA_Kepler end
abstract type NVIDIA_Maxwell <: NVIDIA_Kepler2 end
abstract type NVIDIA_Maxwell2 <: NVIDIA_Maxwell end
abstract type NVIDIA_Pascal <: NVIDIA_Maxwell2 end
abstract type NVIDIA_Volta <: NVIDIA_Pascal end
abstract type NVIDIA_Turing <: NVIDIA_Volta end
abstract type NVIDIA_Ampere <: NVIDIA_Turing end
abstract type NVIDIA_Hopper <: NVIDIA_Ampere end

# Accelerator Models

abstract type AcceleratorModel <: QualifierFeature end

abstract type NVIDIA_Model <: AcceleratorArch end

abstract type NVIDIATesla <: NVIDIA_Model end

abstract type NVIDIA_A100 <: NVIDIA_Model end
abstract type NVIDIATesla_T4G <: NVIDIATesla end