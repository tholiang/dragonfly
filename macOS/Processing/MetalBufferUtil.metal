//
//  MetalBufferUtil.metal
//  dragonfly
//
//  Created by Thomas Liang on 1/2/25.
//

#include <metal_stdlib>
using namespace metal;
#include "MetalBufferUtil.h"

constant void *_GetConstantBufferElement(constant Buffer *buf, unsigned long offset, unsigned long idx, unsigned int obj_size) {
    constant char *data = ((constant char *) buf) + sizeof(BufferHeader);
    return data + offset + (idx * obj_size);
}

device void *_GetDeviceBufferElement(device Buffer *buf, unsigned long offset, unsigned long idx, unsigned int obj_size) {
    device char *data = ((device char *) buf) + sizeof(BufferHeader);
    return data + offset + (idx * obj_size);
}

unsigned long PanelBufOffset(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long pid) {
    constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
    
    unsigned long offset = 0;
    for (unsigned long i = 0; i < pid; i++) {
        offset += panel_info->panel_buffer_headers[outbuf_idx].size;
    }
    
    return offset;
}

unsigned long ComputeBufOffset(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long pid) {
    constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
    
    unsigned long offset = 0;
    for (unsigned long i = 0; i < pid; i++) {
        offset += panel_info->compute_buffer_headers[outbuf_idx].size;
    }
    
    return offset;
}

BufferHeader GetPanelSubBufferHeader(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long pid) {
    constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
    return panel_info->panel_buffer_headers[outbuf_idx];
}

BufferHeader GetComputeSubBufferHeader(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long pid) {
    constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
    return panel_info->compute_buffer_headers[outbuf_idx];
}

constant void *GetConstantPanelBufElementFromRelIdx(const constant Buffer *panel_info_buffer, const constant Buffer *data_buffer, unsigned long outbuf_idx, unsigned long pid, unsigned int rvid, unsigned int obj_size) {
    constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
    unsigned long panel_val_start = panel_info->panel_buffer_starts[outbuf_idx];
    return _GetConstantBufferElement(data_buffer, panel_val_start, rvid, obj_size);
}

device void *GetDevicePanelBufElementFromRelIdx(const constant Buffer *panel_info_buffer, device Buffer *data_buffer, unsigned long outbuf_idx, unsigned long pid, unsigned int rvid, unsigned int obj_size) {
    constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
    unsigned long panel_val_start = panel_info->panel_buffer_starts[outbuf_idx];
    return _GetDeviceBufferElement(data_buffer, panel_val_start, rvid, obj_size);
}

constant void *GetConstantComputeBufElementFromRelIdx(const constant Buffer *panel_info_buffer, const constant Buffer *data_buffer, unsigned long outbuf_idx, unsigned long pid, unsigned int rvid, unsigned int obj_size) {
    constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
    unsigned long panel_val_start = panel_info->compute_buffer_starts[outbuf_idx];
    return _GetConstantBufferElement(data_buffer, panel_val_start, rvid, obj_size);
}

device void *GetDeviceComputeBufElementFromRelIdx(const constant Buffer *panel_info_buffer, device Buffer *data_buffer, unsigned long outbuf_idx, unsigned long pid, unsigned int rvid, unsigned int obj_size) {
    constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
    unsigned long panel_val_start = panel_info->compute_buffer_starts[outbuf_idx];
    return _GetDeviceBufferElement(data_buffer, panel_val_start, rvid, obj_size);
}

unsigned long RelComputeToGlobalIdx(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long pid, unsigned int rvid, unsigned int obj_size) {
    constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
    unsigned long panel_val_start = panel_info->compute_buffer_starts[outbuf_idx];
    return rvid + (panel_val_start / obj_size);
}

vec_int2 GlobalToPanelBufIdx(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned int value_idx, unsigned int obj_size) {
    unsigned int cur_total_idx = 0;
    unsigned long num_panels = panel_info_buffer->size / sizeof(PanelBufferInfo);
    for (unsigned long pid = 0; pid < num_panels; pid++) {
        constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
        BufferHeader panel_buffer_header = panel_info->panel_buffer_headers[outbuf_idx];
        unsigned long num_elems = panel_buffer_header.size / obj_size;
        if (cur_total_idx + num_elems > value_idx) {
            return vec_make_int2(pid, value_idx - cur_total_idx);
        }
        cur_total_idx += num_elems;
    }
    return vec_make_int2(-1, -1);
}

vec_int2 GlobalToComputeBufIdx(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned int value_idx, unsigned int obj_size) {
    unsigned int cur_total_idx = 0;
    unsigned long num_panels = panel_info_buffer->size / sizeof(PanelBufferInfo);
    for (unsigned long pid = 0; pid < num_panels; pid++) {
        constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
        BufferHeader panel_buffer_header = panel_info->compute_buffer_headers[outbuf_idx];
        unsigned long num_elems = panel_buffer_header.size / obj_size;
        if (cur_total_idx + num_elems > value_idx) {
            return vec_make_int2(pid, value_idx - cur_total_idx);
        }
        cur_total_idx += num_elems;
    }
    return vec_make_int2(-1, -1);
}

vec_int2 GlobalToCompiledBufIdx(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long cbki_idx, unsigned int value_idx, unsigned int obj_size) {
    unsigned int cur_total_idx = 0;
    unsigned long num_panels = panel_info_buffer->size / sizeof(PanelBufferInfo);
    for (unsigned long pid = 0; pid < num_panels; pid++) {
        constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
        unsigned long source_size = panel_info->compiled_buffer_key_indices[cbki_idx+1] - panel_info->compiled_buffer_key_indices[cbki_idx];
        unsigned long num_elems = source_size / obj_size;
        if (cur_total_idx + num_elems > value_idx) {
            return vec_make_int2(pid, value_idx - cur_total_idx);
        }
        cur_total_idx += num_elems;
    }
    return vec_make_int2(-1, -1);
}

vec_int2 GlobalToCompiledBufIdx(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long start_cbki_idx, unsigned long end_cbki_idx, unsigned int value_idx, unsigned int obj_size) {
    unsigned int cur_total_idx = 0;
    unsigned long num_panels = panel_info_buffer->size / sizeof(PanelBufferInfo);
    for (unsigned long pid = 0; pid < num_panels; pid++) {
        constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
        unsigned long num_elems = panel_info->compiled_buffer_key_indices[end_cbki_idx+1] - panel_info->compiled_buffer_key_indices[start_cbki_idx];
        if (cur_total_idx + num_elems > value_idx) {
            return vec_make_int2(pid, value_idx - cur_total_idx);
        }
        cur_total_idx += num_elems;
    }
    return vec_make_int2(-1, -1);
}

unsigned long SourceToPanelCompiledIndex(const constant Buffer *panel_info_buffer, unsigned long pid, unsigned long cbki_idx, unsigned long svid) {
    constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
    return panel_info->compiled_buffer_key_indices[cbki_idx] + svid;
}

unsigned long PanelCompiledToSourceIndex(const constant Buffer *panel_info_buffer, unsigned long pid, unsigned long cbki_idx, unsigned long rvid) {
    constant PanelBufferInfo *panel_info = (constant PanelBufferInfo *) _GetConstantBufferElement(panel_info_buffer, 0, pid, sizeof(PanelBufferInfo));
    return rvid - panel_info->compiled_buffer_key_indices[cbki_idx];
}
