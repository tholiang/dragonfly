#include "Window.h"

Window::Window(WindowAttributes attr) : attr_(attr) {
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) {
        dirty_compiled_panel_buffers_[i] = false;
        compiled_panel_buffers_[i] = NULL;
    }

    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        compute_buffers_[i] = NULL;
    }
}

Window::~Window() {

}

void Window::Update() {
    PrepareBuffers();
}

vec_float2 Window::TranslatePixel(vec_float2 p) {
    p.x = (p.x / attr_.screen_width)*2 - 1;
    p.y = -((p.y / attr_.screen_height)*2 - 1);
    return p;
}

void Window::UpdateAttributes(WindowAttributes attr) {
    attr_ = attr;
}

WindowAttributes Window::GetAttributes() {
    return attr_;
}

void Window::HandleKeyPresses(int key, bool down) {
    switch (key) {
        case 119:
            keys_.w = down;
            break;
        case 97:
            keys_.a = down;
            break;
        case 115:
            keys_.s = down;
            break;
        case 100:
            keys_.d = down;
            break;
        case 32:
            keys_.space = down;
            break;
        case 122:
            // z
            // TODO
            // if (keys_.command && down) Undo();
            break;
        case 1073742049:
            keys_.shift = down;
            break;
        case 1073742048:
            keys_.control = down;
            break;
        case 1073742054:
            keys_.option = down;
            break;
        case 1073742055:
            keys_.command = down;
            break;
        default:
            break;
    }
}

void Window::HandleMouseClick(vec_float2 loc, bool left, bool down) {
    if (left) {
        mouse_.left = down;
    } else {
        mouse_.right = down;
    }
}

void Window::HandleMouseMovement(float x, float y, float dx, float dy) {
    mouse_.location.x = x / attr_.screen_width;
    mouse_.location.y = y / attr_.screen_height;
    mouse_.movement.x = dx / attr_.screen_width;
    mouse_.movement.y = dy / attr_.screen_height;
}

void Window::MakeViewWindow(Scene *scene) {
    ViewPanel view_panel = ViewPanel(vec_make_float4(0, 0, 1, 1), scene);
    panels_.push_back(view_panel);
}

unsigned int Window::NumPanels() {
    return panels_.size();
}

std::vector<Panel> *Window::GetPanels() {
    return &panels_;
}

Panel *Window::GetPanel(unsigned int i) {
    assert(i < panels_.size());
    return &panels_[i];
}

void Window::PrepareBuffers() {
    // if the number of panels have changed, regenerate everything
    bool regen_all = panel_info_buffer_ == NULL || panel_info_buffer_->size != panels_.size();
    if (regen_all) {
        if (panel_info_buffer_ != NULL) { free(panel_info_buffer_); }
        unsigned long data_size = panels_.size() * sizeof(PanelBufferInfo);
        panel_info_buffer_ = (Buffer *) calloc(sizeof(BufferHeader) + data_size, 1);
        panel_info_buffer_->size = data_size;
        panel_info_buffer_->capacity = data_size;
        dirty_panel_info_buffer_ = true;
    }

    // set some info buffer stuff
    for (int j = 0; j < panels_.size(); j++) {
        PanelBufferInfo *info = (PanelBufferInfo *) GetBufferElement(panel_info_buffer_, j, sizeof(PanelBufferInfo));
        info->borders = panels_[j].GetBorders();
        memcpy(&info->compiled_buffer_key_indices, panels_[j].GetCompiledBufferKeyIndices(), sizeof(uint64_t)*CBKI_NUM_KEYS);
    }


    /* PANEL OUT BUFFERS */
    // get out buffers for all panels
    std::vector<Buffer **> panel_out_buffers;
    for (int j = 0; j < panels_.size(); j++) { panel_out_buffers.push_back(panels_[j].GetOutBuffers()); }
    
    // compile the panel out buffers
    for (int i = 0; i < PNL_NUM_OUTBUFS; i++) {
        unsigned long total_size = 0;
        unsigned long total_capacity = 0;
        bool reorg = false;
        for (int j = 0; j < panels_.size(); j++) {
            // set panel info start idx (to what it will be)
            PanelBufferInfo *info = (PanelBufferInfo *) GetBufferElement(panel_info_buffer_, j, sizeof(PanelBufferInfo));
            if (info->panel_buffer_starts[i] != total_capacity) { // if start it off - then some buffer capacities were changed
                info->panel_buffer_starts[i] = total_capacity;
                reorg = true;
            }
            
            if (panel_out_buffers[j][i] == NULL) {
                info->panel_buffer_headers[i].size = 0;
                info->panel_buffer_headers[i].capacity = 0;
                continue;
            }
            
            BufferHeader header = *((BufferHeader *) panel_out_buffers[j][i]);
            total_size += header.size;
            total_capacity += header.capacity;
            info->panel_buffer_headers[i] = header;
        }

        // regenerate compiled buffer if needed
        bool regen = regen_all || compiled_panel_buffers_[i] == NULL || total_capacity != compiled_panel_buffers_[i]->capacity;
        if (regen) {
            if (compiled_panel_buffers_[i] != NULL) { free(compiled_panel_buffers_[i]); }
            compiled_panel_buffers_[i] = (Buffer *) malloc(sizeof(BufferHeader) + total_capacity);
            compiled_panel_buffers_[i]->capacity = total_capacity;
        }
        compiled_panel_buffers_[i]->size = total_size;

        // fix data
        for (int j = 0; j < panels_.size(); j++) {
            if (panel_out_buffers[j][i] == NULL) { continue; }
            PanelBufferInfo *info_buf = (PanelBufferInfo *) GetBufferElement(panel_info_buffer_, j, sizeof(PanelBufferInfo));
            if (reorg || regen || panels_[j].IsBufferDirty(i)) {
                void *panel_buffer_start = compiled_panel_buffers_[i]+info_buf->panel_buffer_starts[i];
                char *panel_out_buffer_data = ((char *) panel_out_buffers[j][i]) + sizeof(BufferHeader);
                memcpy(panel_buffer_start, (void *) panel_out_buffer_data, panel_out_buffers[j][i]->capacity);

                panels_[j].CleanBuffer(i);
                dirty_compiled_panel_buffers_[j] = true;
            }
        }
    }


    /* COMPUTE BUFFERS */
    // get (unset) in buffers for panel
    std::vector<Buffer **> panel_in_buffers;
    for (int j = 0; j < panels_.size(); j++) { panel_in_buffers.push_back(panels_[j].GetInBuffers(true)); }

    // compile the compute (out) buffers
    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        // similar to above except we just always set the contained data since we don't change that much
        unsigned long total_size = 0;
        unsigned long total_capacity = 0;
        for (int j = 0; j < panels_.size(); j++) {
            PanelBufferInfo *info = (PanelBufferInfo *) GetBufferElement(panel_info_buffer_, j, sizeof(PanelBufferInfo));
            info->compute_buffer_starts[j] = total_size;

            BufferHeader header = *((BufferHeader *) panel_in_buffers[j][i]);
            total_size += header.size;
            total_capacity += header.capacity;
            info->compute_buffer_headers[i] = header;
        }

        // regenerate compiled buffer if needed
        if (regen_all || compute_buffers_[i] == NULL || total_capacity != compute_buffers_[i]->capacity) {
            if (compute_buffers_[i] != NULL) { free(compute_buffers_[i]); }
            compute_buffers_[i] = (Buffer *) malloc(sizeof(BufferHeader) + total_capacity);
            compute_buffers_[i]->capacity = total_capacity;
            dirty_compute_buffers_[i] = true;
        }
        compute_buffers_[i]->size = total_size;
    }
    
    UpdateComputeCompiledBuffers();
}

void Window::UpdateComputeCompiledBuffers() {
    unsigned long total_comp_vertex_count = 0;
    for (int j = 0; j < panels_.size(); j++) {
        PanelBufferInfo *info = (PanelBufferInfo *) GetBufferElement(panel_info_buffer_, j, sizeof(PanelBufferInfo));
        Buffer **panel_extra_buffers = panels_[j].GetXBuffers();
        
        // scene faces
        if (panel_extra_buffers[PNL_SCFACE_XBUF] != NULL && panels_[j].IsXBufferDirty(PNL_SCFACE_XBUF)) {
            unsigned long v_offset = total_comp_vertex_count + info->compiled_buffer_key_indices[CBKI_V_SCENE_START_IDX];
            unsigned long rf_offset = info->compiled_buffer_key_indices[CBKI_F_SCENE_START_IDX];
            Buffer *panel_sc_faces = panel_extra_buffers[PNL_SCFACE_XBUF];
            for (int k = 0; k < panel_sc_faces->size; k++) {
                Face *pf = (Face *) GetBufferElement(panel_sc_faces, k, sizeof(Face));
                Face *cf = (Face *) GetBufferElement(compute_buffers_[CPT_COMPCOMPFACE_OUTBUF_IDX], k+rf_offset, sizeof(Face), info->compute_buffer_starts[CPT_COMPCOMPFACE_OUTBUF_IDX]);
                *cf = *pf;
                cf->vertices[0] += v_offset;
                cf->vertices[1] += v_offset;
                cf->vertices[2] += v_offset;
            }
            panels_[j].CleanXBuffer(PNL_SCFACE_XBUF);
            dirty_compute_buffers_[CPT_COMPCOMPFACE_OUTBUF_IDX] = true;
        }
        
        // control faces
        if (panel_extra_buffers[PNL_CTFACE_XBUF] != NULL && panels_[j].IsXBufferDirty(PNL_CTFACE_XBUF)) {
            unsigned long v_offset = total_comp_vertex_count + info->compiled_buffer_key_indices[CBKI_V_CONTROL_START_IDX];
            unsigned long rf_offset = info->compiled_buffer_key_indices[CBKI_F_SCENE_START_IDX];
            Buffer *panel_ct_faces = panel_extra_buffers[PNL_CTFACE_XBUF];
            for (int k = 0; k < panel_ct_faces->size; k++) {
                Face *pf = (Face *) GetBufferElement(panel_ct_faces, k, sizeof(Face));
                Face *cf = (Face *) GetBufferElement(compute_buffers_[CPT_COMPCOMPFACE_OUTBUF_IDX], k+rf_offset, sizeof(Face), info->compute_buffer_starts[CPT_COMPCOMPFACE_OUTBUF_IDX]);
                *cf = *pf;
                cf->vertices[0] += v_offset;
                cf->vertices[1] += v_offset;
                cf->vertices[2] += v_offset;
            }
            panels_[j].CleanXBuffer(PNL_CTFACE_XBUF);
            dirty_compute_buffers_[CPT_COMPCOMPFACE_OUTBUF_IDX] = true;
        }
        
        // ui faces
        if (panel_extra_buffers[PNL_UIFACE_XBUF] != NULL && panels_[j].IsXBufferDirty(PNL_UIFACE_XBUF)) {
            unsigned long v_offset = total_comp_vertex_count + info->compiled_buffer_key_indices[CBKI_V_UI_START_IDX];
            unsigned long rf_offset = info->compiled_buffer_key_indices[CBKI_F_SCENE_START_IDX];
            Buffer *panel_ui_faces = panel_extra_buffers[PNL_UIFACE_XBUF];
            for (int k = 0; k < panel_ui_faces->size; k++) {
                UIFace *pf = (UIFace *) GetBufferElement(panel_ui_faces, k, sizeof(Face));
                Face *cf = (Face *) GetBufferElement(compute_buffers_[CPT_COMPCOMPFACE_OUTBUF_IDX], k+rf_offset, sizeof(Face), info->compute_buffer_starts[CPT_COMPCOMPFACE_OUTBUF_IDX]);
                cf->color = pf->color;
                cf->vertices[0] = pf->vertices[0] + v_offset;
                cf->vertices[1] = pf->vertices[1] + v_offset;
                cf->vertices[2] = pf->vertices[2] + v_offset;
            }
            panels_[j].CleanXBuffer(PNL_UIFACE_XBUF);
            dirty_compute_buffers_[CPT_COMPCOMPFACE_OUTBUF_IDX] = true;
        }
        
        // scene edges
        if (panel_extra_buffers[PNL_SCEDGE_XBUF] != NULL && panels_[j].IsXBufferDirty(PNL_SCEDGE_XBUF)) {
            unsigned long v_offset = total_comp_vertex_count + info->compiled_buffer_key_indices[CBKI_V_SCENE_START_IDX];
            unsigned long re_offset = info->compiled_buffer_key_indices[CBKI_E_SCENE_START_IDX];
            Buffer *panel_sc_edges = panel_extra_buffers[PNL_SCEDGE_XBUF];
            for (int k = 0; k < panel_sc_edges->size; k++) {
                vec_int2 *pf = (vec_int2 *) GetBufferElement(panel_sc_edges, k, sizeof(vec_int2));
                vec_int2 *cf = (vec_int2 *) GetBufferElement(compute_buffers_[CPT_COMPCOMPEDGE_OUTBUF_IDX], k+re_offset, sizeof(vec_int2), info->compute_buffer_starts[CPT_COMPCOMPEDGE_OUTBUF_IDX]);
                *cf = *pf;
                cf->x += v_offset;
                cf->y += v_offset;
            }
            panels_[j].CleanXBuffer(PNL_SCFACE_XBUF);
            dirty_compute_buffers_[CPT_COMPCOMPFACE_OUTBUF_IDX] = true;
        }
        
        total_comp_vertex_count += info->compiled_buffer_key_indices[CBKI_V_SIZE_IDX];
    }
}

bool Window::IsPanelBufferInfoDirty() {
    return dirty_panel_info_buffer_;
}

void Window::CleanPanelBufferInfo() {
    dirty_panel_info_buffer_ = false;
}

Buffer *Window::GetPanelBufferInfo() {
    return panel_info_buffer_;
}

bool Window::IsCompiledPanelBufferDirty(unsigned long buf) {
    assert(buf < PNL_NUM_OUTBUFS);
    return dirty_compiled_panel_buffers_[buf];
}

void Window::CleanCompiledPanelBuffer(unsigned long buf) {
    assert(buf < PNL_NUM_OUTBUFS);
    dirty_compiled_panel_buffers_[buf] = false;
}

Buffer **Window::GetCompiledPanelBuffers() {
    return compiled_panel_buffers_;
}


bool Window::IsComputeBufferDirty(unsigned long buf) {
    assert(buf < CPT_NUM_OUTBUFS);
    return dirty_compute_buffers_[buf];
}

void Window::CleanComputeBuffer(unsigned long buf) {
    assert(buf < CPT_NUM_OUTBUFS);
    dirty_compute_buffers_[buf] = false;
}

Buffer **Window::GetComputeBuffers() {
    return compute_buffers_;
}
