# cython: language_level=3
# cython: cdivision=True
# distutils: language=c++
from libc.stdint cimport int32_t, int64_t, uint32_t
from libc.stddef cimport wchar_t

cdef extern from "NativeApi.h" nogil:
    """
#define LibSvcApi __declspec(dllimport)
    """
    ctypedef void(*ProgCallback)(size_t, size_t)
    enum LibSvcExecutionProviders:
        CPU
        CUDA
        DML
    enum LibSvcModelType:
        Vits
        Diffusion
        Reflow
    struct LibSvcSlicerSettings:
        int32_t SamplingRate
        double Threshold
        double MinLength
        int32_t WindowLength
        int32_t HopSize

    struct LibSvcParams:
        float NoiseScale                        #噪声修正因子          0-10
        int64_t Seed                         #种子
        int64_t SpeakerId                         #角色ID
        size_t SrcSamplingRate                   #源采样率
        int64_t SpkCount                          #模型角色数


        float IndexRate                          #索引比               0-1
        float ClusterRate                         #聚类比               0-1
        float DDSPNoiseScale                    #DDSP噪声修正因子      0-10
        float Keys                                  #升降调               -64-64
        size_t MeanWindowLength                       #均值滤波器窗口大小     1-20
        size_t Pndm                                 #Diffusion加速倍数    1-200
        size_t Step                                #Diffusion总步数      1-1000
        float TBegin
        float TEnd
        wchar_t* Sampler                 #Diffusion采样器
        wchar_t* ReflowSampler           #Reflow采样器
        wchar_t* F0Method                #F0提取算法
        int32_t UseShallowDiffusion                 #使用浅扩散
        void* _VocoderModel

    struct DiffusionSvcPaths:
        wchar_t* Encoder
        wchar_t* Denoise
        wchar_t* Pred
        wchar_t* After
        wchar_t* Alpha
        wchar_t* Naive
        wchar_t* DiffSvc
	#
    struct ReflowSvcPaths:
        wchar_t* Encoder
        wchar_t* VelocityFn
        wchar_t* After

    struct VitsSvcPaths:
        wchar_t* VitsSvc

    struct LibSvcClusterConfig:
        int64_t ClusterCenterSize
        wchar_t* Path
        wchar_t* Type

    struct LibSvcHparams:
        wchar_t* TensorExtractor
        wchar_t* HubertPath
        DiffusionSvcPaths DiffusionSvc
        VitsSvcPaths VitsSvc
        ReflowSvcPaths ReflowSvc
        LibSvcClusterConfig Cluster

        int32_t SamplingRate

        int32_t HopSize
        int64_t HiddenUnitKDims
        int64_t SpeakerCount
        int32_t EnableCharaMix
        int32_t EnableVolume
        int32_t VaeMode

        int64_t MelBins
        int64_t Pndms
        int64_t MaxStep
        float SpecMin
        float SpecMax
        float Scale

    ctypedef void* FloatVector
    ctypedef void* DoubleDimsFloatVector
    ctypedef void* Int16Vector
    ctypedef void* UInt64Vector
    ctypedef void* MelType
    ctypedef void* SliceType
    ctypedef void* SlicesType
    ctypedef void* SvcModel
    ctypedef void* VocoderModel
    ctypedef const void* CFloatVector
    ctypedef const void* CDoubleDimsFloatVector
    ctypedef const void* CInt16Vector
    ctypedef const void* CUInt64Vector
    ctypedef const void* CMelType
    ctypedef const void* CSliceType
    ctypedef const void* CSlicesType



    float* LibSvcGetFloatVectorData(FloatVector _Obj)

    size_t LibSvcGetFloatVectorSize(FloatVector _Obj)

    FloatVector LibSvcGetDFloatVectorData(DoubleDimsFloatVector _Obj, size_t _Index)

    size_t LibSvcGetDFloatVectorSize(DoubleDimsFloatVector _Obj)

    Int16Vector LibSvcAllocateAudio()

    void LibSvcReleaseAudio(Int16Vector _Obj)

    void LibSvcSetAudioLength(Int16Vector _Obj, size_t _Size)

    void LibSvcInsertAudio(Int16Vector _ObjA, Int16Vector _ObjB)

    short* LibSvcGetAudioData(Int16Vector _Obj)

    size_t LibSvcGetAudioSize(Int16Vector _Obj)

    UInt64Vector LibSvcAllocateOffset()

    void LibSvcReleaseOffset(UInt64Vector _Obj)

    void LibSvcSetOffsetLength(UInt64Vector _Obj, size_t _Size)

    size_t* LibSvcGetOffsetData(UInt64Vector _Obj)

    size_t LibSvcGetOffsetSize(UInt64Vector _Obj)

	# Mel - pair<vector<float>, int64_t>

    MelType LibSvcAllocateMel()

    void LibSvcReleaseMel(MelType _Obj)

    FloatVector LibSvcGetMelData(MelType _Obj)

    int64_t LibSvcGetMelSize(MelType _Obj)

	# Slice - MoeVoiceStudioSvcSlice

    Int16Vector LibSvcGetAudio(SliceType _Obj)

    FloatVector LibSvcGetF0(SliceType _Obj)

    FloatVector LibSvcGetVolume(SliceType _Obj)

    DoubleDimsFloatVector LibSvcGetSpeaker(SliceType _Obj)

    int32_t LibSvcGetSrcLength(SliceType _Obj)

    int32_t LibSvcGetIsNotMute(SliceType _Obj)

    void LibSvcSetSpeakerMixDataSize(SliceType _Obj, size_t _NSpeaker)

	# Slices - MoeVoiceStudioSvcData

    SlicesType LibSvcAllocateSliceData()

    void LibSvcReleaseSliceData(SlicesType _Obj)

    wchar_t* LibSvcGetAudioPath(SlicesType _Obj)

    SliceType LibSvcGetSlice(SlicesType _Obj, size_t _Index)

    size_t LibSvcGetSliceCount(SlicesType _Obj)
    # ******************************************Fun**********************************************/

    void LibSvcInit()

    void LibSvcFreeString(wchar_t* _String)

    int32_t LibSvcSetGlobalEnv(uint32_t ThreadCount, uint32_t DeviceID, uint32_t Provider)

    void LibSvcSetMaxErrorCount(size_t Count)

    wchar_t* LibSvcGetError(size_t Index)

    int32_t LibSvcSliceAudio(
		CInt16Vector _Audio, #std::vector<int16_t> By "LibSvcAllocateAudio()"
		const void* _Setting, #Ptr Of LibSvcSlicerSettings
		UInt64Vector _Output #std::vector<size_t> By "LibSvcAllocateOffset()"
	)

    int32_t LibSvcPreprocess(
		CInt16Vector _Audio, #std::vector<int16_t> By "LibSvcAllocateAudio()"
		CUInt64Vector _SlicePos, #std::vector<size_t> By "LibSvcAllocateOffset()"
		int32_t _SamplingRate,
		int32_t _HopSize,
		double _Threshold,
		const wchar_t* _F0Method, #"Dio" "Harvest" "RMVPE" "FCPE"
		SlicesType _Output # Slices By "LibSvcAllocateSliceData()"
	)

    int32_t LibSvcStft(
		CInt16Vector _Audio, #std::vector<int16_t> By "LibSvcAllocateAudio()"
		int32_t _SamplingRate,
		int32_t _Hopsize,
		int32_t _MelBins,
		MelType _Output # Mel By "LibSvcAllocateMel()"
	)

    int32_t LibSvcInferSlice(
		SvcModel _Model, #SingingVoiceConversion Model
		uint32_t _T,
		CSliceType _Slice, # Slices By "LibSvcAllocateSliceData()"
		const void* _InferParams, #Ptr Of LibSvcParams
		size_t* _Process,
		Int16Vector _Output #std::vector<int16_t> By "LibSvcAllocateAudio()"
	)

    int32_t LibSvcShallowDiffusionInference(
		SvcModel _Model, #SingingVoiceConversion Model
		FloatVector _16KAudioHubert,
		MelType _Mel, #Mel By "LibSvcAllocateMel()"
		CFloatVector _SrcF0,
		CFloatVector _SrcVolume,
		CDoubleDimsFloatVector _SrcSpeakerMap,
		int64_t _SrcSize,
		const void* _InferParams, #Ptr Of LibSvcParams
		size_t* _Process,
		Int16Vector _Output #std::vector<int16_t> By "LibSvcAllocateAudio()"
	)

    int32_t LibSvcVocoderEnhance(
		VocoderModel _Model, #Vocoder Model
		MelType _Mel, #Mel By "LibSvcAllocateMel()"
		FloatVector _F0,
		int32_t _VocoderMelBins,
		Int16Vector _Output #std::vector<int16_t> By "LibSvcAllocateAudio()"
	)

    SvcModel LibSvcLoadModel(
		uint32_t _T,
		const void* _Config, #Ptr Of LibSvcParams
		ProgCallback _ProgressCallback,
		uint32_t _ExecutionProvider,
		uint32_t _DeviceID,
		uint32_t _ThreadCount
	)

    int32_t LibSvcUnloadModel(
		uint32_t _T,
		SvcModel _Model
	)

    VocoderModel LibSvcLoadVocoder(wchar_t* VocoderPath)

    int32_t LibSvcUnloadVocoder(VocoderModel _Model)

    int32_t LibSvcReadAudio(wchar_t* _AudioPath, int32_t _SamplingRate, Int16Vector _Output)

    void LibSvcEnableFileLogger(bint _Cond)

    void LibSvcWriteAudioFile(Int16Vector _PCMData, wchar_t* _OutputPath, int32_t _SamplingRate)