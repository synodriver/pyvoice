# cython: language_level=3
# cython: cdivision=True
# distutils: language=c++
cimport cython
from libc.stdint cimport int16_t
from cpython.pycapsule cimport PyCapsule_New
from pyvoice.svc cimport (Int16Vector, LibSvcAllocateAudio, LibSvcGetAudioData,
                          LibSvcGetAudioSize, LibSvcInit, LibSvcReleaseAudio,
                          LibSvcSetAudioLength)

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


    def __cinit__(self, size_t size):
        self._a = LibSvcAllocateAudio()
        if self._a == NULL:
            raise MemoryError
        LibSvcSetAudioLength(self._a, size)
        if self._a == NULL:
            raise MemoryError

    def __dealloc__(self):
        if self._a != NULL:
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
