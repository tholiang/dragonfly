#include "Panel.h"

Panel::Panel(vec_float4 borders, Scene *scene) : borders_(borders), scene_(scene) {
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        in_buffers_[i] = NULL;
    }
    
    for (int i = 0; i < CPT_NUM_KERNELS; i++) {
        panel_kernel_counts_[i] = 0;
    }
    
    InitOutBuffers();
    InitInBuffers();
    InitExtraBuffers();
}

void Panel::InitOutBuffers() {
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) {
        dirty_buffers_[i] = false;
        out_buffers_[i] = NULL;
    }
}

void Panel::InitInBuffers() {
    PrepareCompiledBufferKeyIndices();
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        in_buffers_[i] = NULL;
    }
}

void Panel::InitExtraBuffers() {
    for (int i = 0; i < PNL_NUM_XBUFS; i++) {
        dirty_extra_buffers_[i] = false;
        extra_buffers_[i] = NULL;
    }
}

Panel::~Panel() {

}

void Panel::Update(float fps) {
    HandleInput(fps);
}

void Panel::SetScene(Scene *s) {
    scene_ = s;
}

vec_float4 Panel::GetBorders() { return borders_; }
PanelType Panel::GetType() { return type_; }
PanelElements Panel::GetElements() { return elements_; }
bool Panel::IsBufferDirty(unsigned int buf) { return dirty_buffers_[buf]; }
void Panel::CleanBuffer(unsigned int buf) { dirty_buffers_[buf] = false; }
Buffer **Panel::GetOutBuffers() {
    return out_buffers_;
}
uint64_t *Panel::GetCompiledBufferKeyIndices() {
    // TODO: maybe don't do this everytime
    PrepareCompiledBufferKeyIndices();
    return compiled_buffer_key_indices_;
}
Buffer **Panel::GetInBuffers() {
    return in_buffers_;
}
bool Panel::IsXBufferDirty(unsigned int buf) { return dirty_extra_buffers_[buf]; }
void Panel::CleanXBuffer(unsigned int buf) { dirty_extra_buffers_[buf] = false; }
Buffer **Panel::GetXBuffers() { return extra_buffers_; }
unsigned long *Panel::GetKernelCounts() {
    // TODO: maybe don't do this everytime
    PrepareKernelCounts();
    return panel_kernel_counts_;
}

void Panel::SetInputData(Mouse m, Keys k) {
    keys_ = k;
    mouse_ = m;

    // set mouse location and movement relative to panel
    mouse_.location.x -= borders_.x;
    mouse_.location.y -= borders_.y;
    mouse_.movement.x *= borders_.z;
    mouse_.movement.y *= borders_.w;
}

// default implementation
void Panel::PrepareCompiledBufferKeyIndices() {
    // vertices
    uint32_t vertex_size = 0;
    compiled_buffer_key_indices_[CBKI_V_SCENE_START_IDX] = vertex_size;
    if (elements_.scene) { vertex_size += NumSceneVertices(scene_); }
    compiled_buffer_key_indices_[CBKI_V_CONTROL_START_IDX] = vertex_size; // default no controls
    compiled_buffer_key_indices_[CBKI_V_DOT_START_IDX] = vertex_size;
    if (elements_.slices && scene_ != NULL) { vertex_size += NumSceneDots(scene_); }
    compiled_buffer_key_indices_[CBKI_V_NCIRCLE_START_IDX] = vertex_size;
    if (elements_.nodes && scene_ != NULL) { vertex_size += NumSceneNodes(scene_)*NUM_NODE_CIRLCE_VERTICES; }
    compiled_buffer_key_indices_[CBKI_V_VSQUARE_START_IDX] = vertex_size;
    if (elements_.vertices && scene_ != NULL) { vertex_size += NumSceneVertices(scene_)*NUM_VERTEX_SQUARE_VERTICES; }
    compiled_buffer_key_indices_[CBKI_V_DSQUARE_START_IDX] = vertex_size;
    if (elements_.slices && scene_ != NULL) { vertex_size += NumSceneDots(scene_)*NUM_VERTEX_SQUARE_VERTICES; }
    compiled_buffer_key_indices_[CBKI_V_SPLATE_START_IDX] = vertex_size;
    if (elements_.slices && scene_ != NULL) { vertex_size += scene_->NumSlices()*NUM_SLICE_PLATE_VERTICES; }
    compiled_buffer_key_indices_[CBKI_V_UI_START_IDX] = vertex_size; // default no ui

    compiled_buffer_key_indices_[CBKI_V_SIZE_IDX] = vertex_size;


    // faces
    uint32_t face_size = 0;
    compiled_buffer_key_indices_[CBKI_F_SCENE_START_IDX] = face_size;
    if (elements_.faces && scene_ != NULL ) { face_size += NumSceneFaces(scene_); }
    compiled_buffer_key_indices_[CBKI_F_CONTROL_START_IDX] = face_size; // default no controls
    compiled_buffer_key_indices_[CBKI_F_NCIRCLE_START_IDX] = face_size;
    if (elements_.nodes && scene_ != NULL) { face_size += NumSceneNodes(scene_)*NUM_NODE_CIRLCE_FACES; }
    compiled_buffer_key_indices_[CBKI_F_VSQUARE_START_IDX] = face_size;
    if (elements_.vertices && scene_ != NULL) { face_size += NumSceneVertices(scene_)*NUM_VERTEX_SQUARE_FACES; }
    compiled_buffer_key_indices_[CBKI_F_DSQUARE_START_IDX] = face_size;
    if (elements_.slices && scene_ != NULL) { face_size += NumSceneDots(scene_)*NUM_VERTEX_SQUARE_FACES; }
    compiled_buffer_key_indices_[CBKI_F_SPLATE_START_IDX] = face_size;
    if (elements_.slices && scene_ != NULL) { face_size += scene_->NumSlices()*NUM_SLICE_PLATE_FACES; }
    compiled_buffer_key_indices_[CBKI_F_UI_START_IDX] = face_size; // default no ui

    compiled_buffer_key_indices_[CBKI_F_SIZE_IDX] = face_size;


    // edges
    uint32_t edge_size = 0;
    compiled_buffer_key_indices_[CBKI_E_SCENE_START_IDX] = edge_size;
    if (elements_.edges && scene_ != NULL) { edge_size += NumSceneFaces(scene_)*3; }
    compiled_buffer_key_indices_[CBKI_E_LINE_START_IDX] = edge_size;
    if (elements_.slices && scene_ != NULL) { edge_size += NumSceneLines(scene_); }

    compiled_buffer_key_indices_[CBKI_E_SIZE_IDX] = edge_size;
}

void Panel::PrepareKernelCounts() {
    for (int i = 0; i < CPT_NUM_KERNELS; i++) {
        panel_kernel_counts_[i] = 0;
    }
    
    unsigned long num_scene_nodes = NumSceneNodes(scene_);
    unsigned long num_scene_vertices = NumSceneVertices(scene_);
    unsigned long num_scene_faces = NumSceneFaces(scene_);
    unsigned long num_scene_slices = scene_->NumSlices();
    unsigned long num_scene_dots = NumSceneDots(scene_);
    
    if (elements_.scene) {
        panel_kernel_counts_[CPT_TRANSFORMS_KRN_IDX] = num_scene_nodes;
        panel_kernel_counts_[CPT_VERTEX_KRN_IDX] = num_scene_vertices;
        panel_kernel_counts_[CPT_PROJ_VERTEX_KRN_IDX] = num_scene_vertices;
    }
    
    if (elements_.vertices) {
        panel_kernel_counts_[CPT_VERTEX_SQR_KRN_IDX] = num_scene_vertices;
    }
    
    if (elements_.nodes) {
        panel_kernel_counts_[CPT_PROJ_NODE_KRN_IDX] = num_scene_nodes;
    }
    
    if (elements_.faces && elements_.light) {
        panel_kernel_counts_[CPT_LIGHTING_KRN_IDX] = num_scene_faces;
    }
    
    if (elements_.slices) {
        panel_kernel_counts_[CPT_PROJ_DOT_KRN_IDX] = num_scene_dots;
        panel_kernel_counts_[CPT_SLICE_PLATE_KRN_IDX] = num_scene_slices;
    }
    
    // everything else should be overidden by children
}
