#ifndef Buffers_h
#define Buffers_h

#include <stdio.h>
#include <iostream>
#include <cmath>

#include "Utils.h"
#include "Constants.h"
#include "Vec.h"

namespace DragonflyUtils {
struct BufferHeader {
    uint64_t capacity = 0;
    uint64_t size = 0; // in bytes
    // include all the data here - malloc (bad c++ practice whatever)
    // all data elements should be of the same type (and size)
};

typedef BufferHeader Buffer;

struct PanelBufferInfo {
    vec_float4 borders;
    uint64_t panel_buffer_starts[PNL_NUM_OUTBUFS]; // byte start
    BufferHeader panel_buffer_headers[PNL_NUM_OUTBUFS];
    uint64_t compute_buffer_starts[CPT_NUM_OUTBUFS]; // byte start
    BufferHeader compute_buffer_headers[CPT_NUM_OUTBUFS];
    uint64_t compiled_buffer_key_indices[CBKI_NUM_KEYS];
};

// create buffer
Buffer *CreateBuffer(unsigned long capacity);

// return a pointer to the start of the buffer data
char *BufferData(Buffer *buf);

// return a pointer to an element in a Buffer object, given an index and the size of each element in the buffer
void *GetBufferElement(Buffer *buf, unsigned long idx, unsigned int obj_size);

// same as above with a byte offset
void *GetBufferElement(Buffer *buf, unsigned long idx, unsigned int obj_size, unsigned long offset);

// set an element in a buffer
void SetBufferElement(Buffer *buf, unsigned long idx, unsigned int obj_size, char *data);

// set a section of a buffer data
void SetBufferSubData(Buffer *buf, unsigned long start, unsigned long len, unsigned long obj_size, char *data);

// set a buffers data and resize if needed
void SetDynamicBufferData(Buffer **buf, char *data, unsigned long data_len);

// get total size of a buffer object (including attributes)
unsigned long TotalBufferSize(Buffer *buf);

}

#endif // Buffers_h
