# cython: language_level=3
# cython: cdivision=True
# distutils: language=c++
cimport cython
from cpython.pycapsule cimport PyCapsule_New
from cpython.unicode cimport PyUnicode_FromWideChar
from libc.stddef cimport wchar_t
from libc.stdint cimport int16_t, int32_t, uint32_t

from pyvoice.svc cimport (CInt16Vector, Int16Vector, LibSvcAllocateAudio,
                          LibSvcAllocateOffset, LibSvcAllocateSliceData,
                          LibSvcFreeString, LibSvcGetAudio, LibSvcGetAudioData,
                          LibSvcGetAudioPath, LibSvcGetAudioSize,
                          LibSvcGetError, LibSvcGetOffsetData,
                          LibSvcGetOffsetSize, LibSvcGetSlice,
                          LibSvcGetSliceCount, LibSvcInit, LibSvcReleaseAudio,
                          LibSvcReleaseOffset, LibSvcReleaseSliceData,
                          LibSvcSetAudioLength, LibSvcSetGlobalEnv,
                          LibSvcSetMaxErrorCount, LibSvcSetOffsetLength,
                          LibSvcSliceAudio, LibSvcSlicerSettings, SlicesType,
                          SliceType, UInt64Vector)

LibSvcInit()

@cython.final
@cython.no_gc
@cython.freelist(8)
cdef class Audio:
    cdef:
        Int16Vector _a
        Py_ssize_t[1] shape
        Py_ssize_t[1] strides
        readonly Py_ssize_t view_count
        readonly bint own


    def __cinit__(self, size_t size):
        self._a = LibSvcAllocateAudio()
        if self._a == NULL:
            raise MemoryError
        LibSvcSetAudioLength(self._a, size)
        if self._a == NULL:
            raise MemoryError
        self.own = True

    @staticmethod
    cdef inline Audio from_ptr(Int16Vector v, bint own = True):
        cdef Audio self = Audio.__new__(Audio)
        self._a = v
        self.own = own
        return self

    def __dealloc__(self):
        if self._a != NULL and self.own:
            LibSvcReleaseAudio(self._a)
            self._a = NULL

    cpdef inline realloc(self, size_t size):
        if self.view_count > 0:
            raise ValueError("can't realloc while being viewed")
        LibSvcSetAudioLength(self._a, size)

    def __getbuffer__(self, Py_buffer *buffer, int flags):
        cdef Py_ssize_t itemsize = sizeof(int16_t)
        cdef short* internal = LibSvcGetAudioData(self._a)
        self.shape[0] = <Py_ssize_t>LibSvcGetAudioSize(self._a)
        self.strides[0] = <Py_ssize_t> (<char *> &(internal[1])
                                        - <char *>&(internal[0]))


        buffer.buf = <char *> internal
        buffer.format = 'h'  # short
        buffer.internal = NULL  # see References
        buffer.itemsize = itemsize
        buffer.len = self.shape[0] * itemsize # product(shape) * itemsize
        buffer.ndim = 1
        buffer.obj = self
        buffer.readonly = 0
        buffer.shape = self.shape
        buffer.strides = self.strides
        buffer.suboffsets = NULL  # for pointer arrays only
        self.view_count += 1

    def __releasebuffer__(self, Py_buffer *buffer):
        self.view_count -= 1

    cpdef inline object get_vec(self):
        return PyCapsule_New(self._a, NULL, NULL)


@cython.final
@cython.no_gc
@cython.freelist(8)
cdef class Offset:
    cdef:
        UInt64Vector _a
        Py_ssize_t[1] shape
        Py_ssize_t[1] strides
        readonly Py_ssize_t view_count


    def __cinit__(self, size_t size):
        self._a = LibSvcAllocateOffset()
        if self._a == NULL:
            raise MemoryError
        LibSvcSetOffsetLength(self._a, size)
        if self._a == NULL:
            raise MemoryError

    def __dealloc__(self):
        if self._a != NULL:
            LibSvcReleaseOffset(self._a)
            self._a = NULL

    cpdef inline realloc(self, size_t size):
        if self.view_count > 0:
            raise ValueError("can't realloc while being viewed")
        LibSvcSetOffsetLength(self._a, size)

    def __getbuffer__(self, Py_buffer *buffer, int flags):
        cdef Py_ssize_t itemsize = sizeof(size_t)
        cdef size_t* internal = LibSvcGetOffsetData(self._a)
        self.shape[0] = <Py_ssize_t>LibSvcGetOffsetSize(self._a)
        self.strides[0] = <Py_ssize_t> (<char *> &(internal[1])
                                        - <char *>&(internal[0]))


        buffer.buf = <char *> internal
        buffer.format = 'h'  # short
        buffer.internal = NULL  # see References
        buffer.itemsize = itemsize
        buffer.len = self.shape[0] * itemsize # product(shape) * itemsize
        buffer.ndim = 1
        buffer.obj = self
        buffer.readonly = 0
        buffer.shape = self.shape
        buffer.strides = self.strides
        buffer.suboffsets = NULL  # for pointer arrays only
        self.view_count += 1

    def __releasebuffer__(self, Py_buffer *buffer):
        self.view_count -= 1

    cpdef inline object get_vec(self):
        return PyCapsule_New(self._a, NULL, NULL)

@cython.final
@cython.no_gc
@cython.freelist(8)
cdef class Slice:
    cdef:
        SliceType _a

    @staticmethod
    cdef inline Slice from_ptr(SliceType s):
        cdef Slice self = Slice.__new__(Slice)
        self._a = s
        return self

    cpdef inline Audio get_audio(self):
        cdef Int16Vector ret = LibSvcGetAudio(self._a)
        cdef Audio audio = Audio.from_ptr(ret, False)
        return Audio

    cpdef inline object get_vec(self):
        return PyCapsule_New(self._a, NULL, NULL)


@cython.final
@cython.no_gc
@cython.freelist(8)
cdef class Slices:
    cdef:
        SlicesType _a


    def __cinit__(self):
        self._a = LibSvcAllocateSliceData()
        if self._a == NULL:
            raise MemoryError

    def __dealloc__(self):
        if self._a != NULL:
            LibSvcReleaseSliceData(self._a)
            self._a = NULL

    @property
    def audio_path(self):
        cdef wchar_t * ret = LibSvcGetAudioPath(self._a)
        try:
            return PyUnicode_FromWideChar(ret, -1)
        finally:
            LibSvcFreeString(ret)

    def __getitem__(self, size_t _Index):
        cdef SliceType newslice = LibSvcGetSlice(self._a, _Index)
        cdef Slice s = Slice.from_ptr(newslice)
        return s

    def __len__(self):
        return LibSvcGetSliceCount(self._a)

    cpdef inline object get_vec(self):
        return PyCapsule_New(self._a, NULL, NULL)

cpdef inline int32_t set_global_env(uint32_t ThreadCount, uint32_t DeviceID, uint32_t Provider):
    return LibSvcSetGlobalEnv(ThreadCount, DeviceID, Provider)

cpdef inline set_max_error_count(size_t Count):
    LibSvcSetMaxErrorCount(Count)

cpdef inline str get_error(size_t Index):
    cdef wchar_t* ret = LibSvcGetError(Index)
    try:
        return PyUnicode_FromWideChar(ret, -1)
    finally:
        LibSvcFreeString(ret)

cpdef inline int32_t slice_audio_into(Audio audio,
                              Offset out,
                              int32_t SamplingRate = 48000,
                              double Threshold = 30.0,
                              double MinLength = 3.0,
                              int32_t WindowLength = 2048,
                              int32_t HopSize = 512):
    cdef LibSvcSlicerSettings setting
    setting.SamplingRate = SamplingRate
    setting.Threshold = Threshold
    setting.MinLength = MinLength
    setting.WindowLength = WindowLength
    setting.HopSize = HopSize

    cdef int32_t ret
    with nogil:
        ret = LibSvcSliceAudio(<CInt16Vector>audio._a, <const void*>&setting,<UInt64Vector>out._a)
    return ret