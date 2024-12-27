#include "Panel.h"

Panel::Panel(vec_float4 borders, Scene *scene) : borders_(borders), scene_(scene) {
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) {
        dirty_buffers_[i] = true;
        out_buffers_[i] = NULL;
    }
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        wanted_buffers_[i] = false;
        in_buffers_[i] = NULL;
    }
}

Panel::~Panel() {

}

void Panel::Update() {
    HandleInput();
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
    PrepareOutBuffers();
    return out_buffers_;
}
uint64_t *Panel::GetCompiledBufferKeyIndices() {
    PrepareCompiledBufferKeyIndices();
    return compiled_buffer_key_indices_;
}
bool Panel::IsBufferWanted(unsigned int buf) { return wanted_buffers_[buf]; }
Buffer **Panel::GetInBuffers(bool realloc) {
    if (realloc) { PrepareInBuffers(); }
    return in_buffers_;
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

void Panel::PrepareInBuffers() {
    PrepareCompiledBufferKeyIndices(); // maybe shouldn't call this every time

    // resize in buffers if needed
    unsigned long inbuf_sizes[CPT_NUM_OUTBUFS];
    inbuf_sizes[CPT_COMPCOMPVERTEX_OUTBUF_IDX] = sizeof(Vertex) * (compiled_buffer_key_indices_[CBKI_V_SIZE_IDX]);
    inbuf_sizes[CPT_COMPCOMPFACE_OUTBUF_IDX] = sizeof(Face) * (compiled_buffer_key_indices_[CBKI_F_SIZE_IDX]);
    inbuf_sizes[CPT_COMPMODELVERTEX_OUTBUF_IDX] = sizeof(Vertex) * NumSceneVertices(scene_); // TODO: + controls vertices
    inbuf_sizes[CPT_COMPMODELNODE_OUTBUF_IDX] = sizeof(Vertex) * NumSceneNodes(scene_);

    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        if (wanted_buffers_[i] && (in_buffers_[i] != NULL && in_buffers_[i]->capacity <= inbuf_sizes[i])) {
            if (in_buffers_[i] != NULL) { free(in_buffers_); }
            unsigned long new_cap = inbuf_sizes[i] * 2;
            in_buffers_[i] = (Buffer *) malloc(sizeof(Buffer) + new_cap);
            in_buffers_[i]->capacity = new_cap;
            in_buffers_[i]->size = inbuf_sizes[i];
        }
    }
}

// default implementation
void Panel::PrepareCompiledBufferKeyIndices() {
    // vertices
    uint32_t vertex_size = 0;
    compiled_buffer_key_indices_[CBKI_V_SCENE_START_IDX] = vertex_size;
    if (elements_.scene && scene_ != NULL ) { vertex_size += NumSceneVertices(scene_); }
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
