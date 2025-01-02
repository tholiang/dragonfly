//
//  Buffers.cpp
//  dragonfly
//
//  Created by Thomas Liang on 1/2/25.
//

#include "Buffers.h"
using namespace DragonflyUtils;

Buffer *DragonflyUtils::CreateBuffer(unsigned long capacity) {
    Buffer *buf = (Buffer *) malloc(sizeof(BufferHeader) + capacity);
    buf->size = 0;
    buf->capacity = capacity;
    return buf;
}

void *DragonflyUtils::GetBufferElement(Buffer *buf, unsigned long idx, unsigned int obj_size) {
    assert(idx < buf->size);

    char *data = ((char *) buf) + sizeof(BufferHeader);
    return data + (idx * obj_size);
}

void *DragonflyUtils::GetBufferElement(Buffer *buf, unsigned long idx, unsigned int obj_size, unsigned long offset) {
    assert(idx < buf->size);

    char *data = ((char *) buf) + sizeof(BufferHeader);
    return data + offset + (idx * obj_size);
}

void DragonflyUtils::SetBufferElement(Buffer *buf, unsigned long idx, unsigned int obj_size, char *data) {
    assert(idx < buf->size);
    
    char *bufdata = ((char *) buf) + sizeof(BufferHeader);
    memcpy(bufdata + (idx*obj_size), data, obj_size);
}

void DragonflyUtils::SetBufferSubData(Buffer *buf, unsigned long start, unsigned long len, unsigned long obj_size, char *data) {
    assert(start + len < buf->size);
    
    char *bufdata = ((char *) buf) + sizeof(BufferHeader);
    memcpy(bufdata + (start*obj_size), data, len*obj_size);
}

void DragonflyUtils::SetDynamicBufferData(Buffer **buf, char *data, unsigned long data_len) {
    if ((*buf)->capacity < data_len) {
        free(*buf);
        *buf = (Buffer *) malloc(sizeof(BufferHeader) + (data_len*2));
        (*buf)->capacity = data_len*2;
    }
    
    (*buf)->size = data_len;
    char *bufdata = ((char *) *buf) + sizeof(BufferHeader);
    memcpy(bufdata, data, data_len);
}

unsigned long DragonflyUtils::TotalBufferSize(Buffer *buf) {
    return sizeof(BufferHeader) + buf->capacity;
}
