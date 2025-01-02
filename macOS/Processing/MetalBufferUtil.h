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
 Shouldn't be used directly
 Get element from (constant) Buffer object at a given index
 args:
 1. buffer - Buffer object
 2. offset - byte offset
 3. index - to query
 4. elem_size - size of each element
 */
constant void *_GetConstantBufferElement(constant Buffer *buf, unsigned long offset, unsigned long idx, unsigned int obj_size);

/*
 Same thing as above but for device data
 */
device void *_GetDeviceBufferElement(device Buffer *buf, unsigned long offset, unsigned long idx, unsigned int obj_size);

/*
 Get the offset (number of elements before) of a certain element type for a panel out buffer
 args:
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. outbuf_idx - panel outbuf idx for value type
 3. pid - panel id
 */
unsigned long PanelBufOffset(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long pid);

/*
 Same as above for compute out buffers
 */
unsigned long ComputeBufOffset(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long pid);

/*
 Get the buffer header of a certain element type for a certain panel in a panel buffer
 args:
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. outbuf_idx - panel outbuf idx for value type
 3. pid - panel id
 */
BufferHeader GetPanelSubBufferHeader(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long pid);

/*
 Same as above for compute out buffers
 */
BufferHeader GetComputeSubBufferHeader(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long pid);

/*
 Get a pointer to element in combined panel buffer given a relative panel index
 args:
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. data_buffer - buffer containing packing of per-panel data
 3. outbuf_idx - panel outbuf idx for value type
 4. pid - panel id
 5. rvid - relative index of element
 6. obj_size - object size per value element
 */
constant void *GetConstantPanelBufElementFromRelIdx(const constant Buffer *panel_info_buffer, const constant Buffer *data_buffer, unsigned long outbuf_idx, unsigned long pid, unsigned int rvid, unsigned int obj_size);

/*
 Same thing as above but for device data
 */
device void *GetDevicePanelBufElementFromRelIdx(const constant Buffer *panel_info_buffer, device Buffer *data_buffer, unsigned long outbuf_idx, unsigned long pid, unsigned int rvid, unsigned int obj_size);

/*
 Same thing as above but for const compute buffer data
 */
constant void *GetConstantComputeBufElementFromRelIdx(const constant Buffer *panel_info_buffer, const constant Buffer *data_buffer, unsigned long outbuf_idx, unsigned long pid, unsigned int rvid, unsigned int obj_size);

/*
 Same thing as above but for device compute buffer data
 */
device void *GetDeviceComputeBufElementFromRelIdx(const constant Buffer *panel_info_buffer, device Buffer *data_buffer, unsigned long outbuf_idx, unsigned long pid, unsigned int rvid, unsigned int obj_size);

/*
 Same as above but returns the index
 Assumes that there is no garbage in between compute outbufs
 */
unsigned long RelComputeToGlobalIdx(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long pid, unsigned int rvid, unsigned int obj_size);

/*
 return (panel id, panel-relative index) from a global index for a panel output buffer
 args:
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. outbuf_idx - panel outbuf idx for value type
 3. value_idx - to find panel for. note that this is not directly translatable to the data buffer index, which contains some garbage in between panel data
 4. obj_size - object size per value element
 */
vec_int2 GlobalToPanelBufIdx(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned int value_idx, unsigned int obj_size);

/*
 return (panel id, panel-relative index) from a global index for a compute output buffer
 args:
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. outbuf_idx - panel outbuf idx for value type
 3. value_idx - to find panel for. note that this is not directly translatable to the data buffer index, which contains some garbage in between panel data
 4. obj_size - object size per value element
 */
vec_int2 GlobalToComputeBufIdx(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned int value_idx, unsigned int obj_size);

/*
 return (panel id, panel-relative index) from global index for a single source in a compiled buffer
 args:
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. outbuf_idx - compute outbuf idx for value type
 3. cbki_idx - index of compiled buffer key indices for source
 3. value_idx - to find panel for. note that this is not directly translatable to the data buffer index, which contains some garbage in between panel data
 4. obj_size - object size per value element
 */
vec_int2 GlobalToCompiledBufIdx(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long cbki_idx, unsigned int value_idx, unsigned int obj_size);

/*
 above but it allows multiple contiguous cbki idxs
 idxs are inclusive
 */
vec_int2 GlobalToCompiledBufIdx(const constant Buffer *panel_info_buffer, unsigned long outbuf_idx, unsigned long start_cbki_idx, unsigned long end_cbki_idx, unsigned int value_idx, unsigned int obj_size);

/*
 return panel-relative compiled buffer index from source-relative index (still relatve to panel)
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. pid - panel index
 3. cbki_idx - index of compiled buffer key index to search for
 4. svid - relative vid to panel and source type
 */
unsigned long SourceToPanelCompiledIndex(const constant Buffer *panel_info_buffer, unsigned long pid, unsigned long cbki_idx, unsigned long svid);

/*
 return source-relative index from compiled buffer index (still relatve to panel)
 1. panel_info_buffer - single Buffer object containing PanelBufferInfo objects
 2. pid - panel index
 3. cbki_idx - index of compiled buffer key index to search for
 4. rvid - relative vid to panel
 */
unsigned long PanelCompiledToSourceIndex(const constant Buffer *panel_info_buffer, unsigned long pid, unsigned long cbki_idx, unsigned long rvid);


#endif /* MetalBufferUtil_h */
