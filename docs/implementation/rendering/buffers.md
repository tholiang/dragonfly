# buffers

the buffer flow spans panels, windows, and the compute and renderer, looking something like:

```
panel <-> window -> compute -> renderer
            ^         |
            |_________|
```

the first important datatype is the `BufferHeader`:

```
BufferHeader {
    unsigned long size; // the number of bytes of actual data
    unsigned long capacity; // the total space allocated, including padding
}
```
we generally keep a larger capacity than size to allow the addition of elements without complete reallocation of the buffer

## panel buffer flow

### 1. panel

panels generate buffers for their own output data - including scene, controls, and ui information

each data source (e.g. scene or controls), has a buffer for its data

each buffer is stored in the panel object as a `BufferHeader` followed immediately by the data in memory. these buffers also have an associated "dirtyness" - if the panel changes a certain buffer's' information, it marks it as dirty

panels also generate empty buffers for information they want to receive from the compute, like projected vertex values. compute output buffers contain packed data from various sources, so panels also have to keep an source index tracker, `CompiledBufferKeyIndices`. this will be explained further later

### 2. window

windows compile data across panels into buffers for each data source, so that the buffer for a single data source contains data from every panel

the actual compiled buffers look something like: `BufferHeader[[panel1 data][panel2 data][panel3 data]]`. note that the data for a panel contains **all** of a panel buffers data, including padding, so that `[panel1 data]` contains `capacity` bytes. also note that the `capacity` and `size` attributes of the `BufferHeader` are equal in these buffers

we don't include the `BufferHeader`s of each panels data directly in the compiled buffers. instead, windows also maintain an array of `PanelInfo`s, each containing some metadata about a specific panel:

```
PanelInfo {
    vec_float4 borders;
    uint64_t panel_buffer_starts[PNL_NUM_OUTBUFS]; // byte start
    BufferHeader panel_buffer_headers[PNL_NUM_OUTBUFS];
    uint64_t compute_buffer_starts[CPT_NUM_OUTBUFS]; // byte start
    BufferHeader compute_buffer_headers[CPT_NUM_OUTBUFS];
    CompiledBufferKeyIndices compiled_key_indices;
}
```
the `_buffer_starts` attributes describe the byte index, for a given data source, of where the associated panel's data starts. the corresponding `_buffer_headers` value will given the panel's data capacity and size for that data source

the array of `PanelInfo`s is also compiled into its own buffer: `BufferHeader[PanelInfo PanelInfo PanelInfo]`

at each frame, the window must check if its current compiled buffers are still up to date with the panel buffers. it does this by comparing its metadata with the panels to update sizes/capacities. it also checks if any panel buffers are labeled `dirty`. if so, it replaces the data in these buffers, and tells the panel to mark the buffer `clean`

### 3. compute
the cpu side of the compute only needs to copy the window's buffers into gpu accessible space. compute gpu functions operate on the entirety of data from a given datasource (across all panels). by the nature of these functions, the only identifying information about what data a thread should be operating on is given by a single 1d value. [add panel index translation here]

## compute buffer flow

### 1. compute

the primary outputs of the compute are three buffers - containing the vertex, face, and edge data, respectively, for everything to be rendered on screen

similar to compiled panel outbufs, these buffers are split by panel order, and packed tightly, so there there is no padding between panels. additionally, for face and edge buffers, vertex indices are directly addressing the compiled vertex buffer. this makes render functions simpler as they don't have to calculate anything per panel. there does exist padding at the very end of the buffers


### 2. window

the window receives these large buffers from the compute, then splits them per-panel based on information in its `PanelInfo` buffer. it also corrects the vertex indices in the face and edge buffers per-panel so that they are relative to the panel

### 3. panel

a panel receives its respective corrected section of the compute output from the window. this data also represents multiple sources of data (e.g. the compiled vertex buffer contains projected model vertices, control model vertices, and ui element vertices all in one buffer). these are split up via `CompiledBufferKeyIndices` objects

```
CompiledBufferKeyIndices {
    uint32_t compiled_vertex_size = 0;
    uint32_t compiled_vertex_scene_start = 0;
    uint32_t compiled_vertex_control_start = 0;
    uint32_t compiled_vertex_dot_start = 0;
    uint32_t compiled_vertex_node_circle_start = 0;
    uint32_t compiled_vertex_vertex_square_start = 0;
    uint32_t compiled_vertex_dot_square_start = 0;
    uint32_t compiled_vertex_slice_plate_start = 0;
    uint32_t compiled_vertex_ui_start = 0;
    
    uint32_t compiled_face_size = 0;
    uint32_t compiled_face_scene_start = 0;
    uint32_t compiled_face_control_start = 0;
    uint32_t compiled_face_node_circle_start = 0;
    uint32_t compiled_face_vertex_square_start = 0;
    uint32_t compiled_face_dot_square_start = 0;
    uint32_t compiled_face_slice_plate_start = 0;
    uint32_t compiled_face_ui_start = 0;
    
    uint32_t compiled_edge_size = 0;
    uint32_t compiled_edge_scene_start = 0;
    uint32_t compiled_edge_line_start = 0;
}
```

these indicate the starting indices for each data source in the compiled compute output buffers, so the panel can easily split up the data to use it
