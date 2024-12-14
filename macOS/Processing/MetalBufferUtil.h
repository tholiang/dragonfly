//
//  MetalBufferUtil.h
//  dragonfly
//
//  Created by Thomas Liang on 12/14/24.
//

#ifndef MetalBufferUtil_h
#define MetalBufferUtil_h
#include "MetalUtil.h"

// buffers
/*
 Get element from (constant) Buffer object at a given index
 args:
 1. buffer - Buffer object
 2. index - to query
 3. elem_size - size of each element
 */
constant void *GetConstantBufferElement(constant Buffer *buf, unsigned long idx, unsigned int obj_size) {
    constant char *data = ((constant char *) buf) + sizeof(Buffer);
    return data + (idx * obj_size);
}

/*
 Same thing as above but for device data
 */
device void *GetDeviceBufferElement(device Buffer *buf, unsigned long idx, unsigned int obj_size) {
    device char *data = ((device char *) buf) + sizeof(Buffer);
    return data + (idx * obj_size);
}

/*
 Get a pointer to element in combined panel buffer given a relative panel index
 args:
 1. panel_info_buffer - single Buffer object containing PanelInfoBuffer objects
 2. data - packing of per-panel Buffers of data
 3. outbuf_idx - panel outbuf idx for value type
 4. pid - panel id
 5. rvid - relative index of element
 6. obj_size - object size per value element
 */
constant void *GetConstantElementFromRelativeIndex(const constant Buffer *panel_info_buffer, const constant char *data, unsigned long outbuf_idx, unsigned long pid, unsigned int rvid, unsigned int obj_size) {
    constant PanelInfoBuffer *panel_info = (constant PanelInfoBuffer *) GetConstantBufferElement(panel_info_buffer, pid, sizeof(PanelInfoBuffer));
    unsigned long panel_val_start = panel_info->panel_buffer_starts[outbuf_idx];
    constant Buffer *buf = (constant Buffer *) (data + panel_val_start);
    return GetConstantBufferElement(buf, rvid, obj_size);
}

/*
 Same thing as above but for device data
 */
device void *GetDeviceElementFromRelativeIndex(const constant Buffer *panel_info_buffer, device char *data, unsigned long outbuf_idx, unsigned long pid, unsigned int rvid, unsigned int obj_size) {
   constant PanelInfoBuffer *panel_info = (constant PanelInfoBuffer *) GetConstantBufferElement(panel_info_buffer, pid, sizeof(PanelInfoBuffer));
   unsigned long panel_val_start = panel_info->panel_buffer_starts[outbuf_idx];
   device Buffer *buf = (device Buffer *) (data + panel_val_start);
   return GetDeviceBufferElement(buf, rvid, obj_size);
}

/*
 return (panel id, panel-relative index) from a given global index
 args:
 1. panel_info_buffer - single Buffer object containing PanelInfoBuffer objects
 2. data - packing of per-panel Buffers of data
 3. outbuf_idx - panel outbuf idx for value type
 4. value_idx - to find panel for
 5. obj_size - object size per value element
 */
vec_int2 GetPanelFromIndex(const constant Buffer *panel_info_buffer, const constant char *data, unsigned long outbuf_idx, unsigned int value_idx, unsigned int obj_size) {
    unsigned int cur_total_idx = 0;
    for (int pid = 0; pid < panel_info_buffer->size; pid++) {
        constant PanelInfoBuffer *panel_info = (constant PanelInfoBuffer *) GetConstantBufferElement(panel_info_buffer, pid, sizeof(PanelInfoBuffer));
        unsigned long panel_val_start = panel_info->panel_buffer_starts[outbuf_idx];
        constant Buffer *buf = (constant Buffer *) (data + panel_val_start);
        unsigned long num_elems = buf->size / obj_size;
        if (cur_total_idx + num_elems > value_idx) {
            return vec_make_int2(pid, value_idx - cur_total_idx);
        }
        cur_total_idx += num_elems;
    }
    return vec_make_int2(-1, -1);
}

#endif /* MetalBufferUtil_h */
