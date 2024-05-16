abstract type PlatformType end

abstract type QuantifierFeature <: PlatformType end
abstract type QualifierFeature <: PlatformType end


# Qualfier feature types

abstract type FCloudProvider <: QualifierFeature end
abstract type FLocale <: QualifierFeature end
abstract type FInstanceType <: QualifierFeature end
abstract type FAccelType <: QualifierFeature end
abstract type FAccelArch <: QualifierFeature end
abstract type FAccelModel <: QualifierFeature end
abstract type FProcessorModel <: QualifierFeature end
abstract type FProcessorArch <: QualifierFeature end
abstract type FStorageType <: QualifierFeature end
abstract type FNetworkType <: QualifierFeature end

abstract type GPU <: FAccelType end
abstract type FPGA <: FAccelType end
abstract type MIC <: FAccelType end
