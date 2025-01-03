#include "ViewPanel.h"

ViewPanel::ViewPanel(vec_float4 borders, Scene *scene) : Panel(borders, scene) {
    type_ = PanelType::View;

    camera_ = MakeCamera();
    elements_.scene = true;
    elements_.faces = true;
    elements_.light = true;
    
    InitOutBuffers();
    InitInBuffers();
    InitExtraBuffers();
}

ViewPanel::~ViewPanel() {
    
}

void ViewPanel::Update(float fps) {
    Panel::Update(fps);
}

void ViewPanel::HandleInput(float fps) {
    HandleCameraMovement(fps);
}

void ViewPanel::InitOutBuffers() {
    Panel::InitOutBuffers();
    
    // camera
    if (out_buffers_[PNL_CAMERA_OUTBUF_IDX] == NULL || out_buffers_[PNL_CAMERA_OUTBUF_IDX]->capacity < sizeof(Camera)) {
        if (out_buffers_[PNL_CAMERA_OUTBUF_IDX] != NULL) { free(out_buffers_[PNL_CAMERA_OUTBUF_IDX]); }
        out_buffers_[PNL_CAMERA_OUTBUF_IDX] = CreateBuffer(sizeof(Camera));
    }
    out_buffers_[PNL_CAMERA_OUTBUF_IDX]->size = sizeof(Camera);
    SetBufferElement(out_buffers_[PNL_CAMERA_OUTBUF_IDX], 0, sizeof(Camera), (char *) camera_);
    dirty_buffers_[PNL_CAMERA_OUTBUF_IDX] = true;

    // lights
    std::vector<SimpleLight> lights = scene_->GetSimpleLights();
    if (out_buffers_[PNL_LIGHT_OUTBUF_IDX] == NULL) { out_buffers_[PNL_LIGHT_OUTBUF_IDX] = CreateBuffer(sizeof(SimpleLight)); }
    SetDynamicBufferData(&out_buffers_[PNL_LIGHT_OUTBUF_IDX], (char *) lights.data(), scene_->NumLights()*sizeof(SimpleLight));
    dirty_buffers_[PNL_LIGHT_OUTBUF_IDX] = true;
    
    // prelit face
    std::vector<Face> faces = GetSceneFaces(scene_);
    if (out_buffers_[PNL_PRELIT_FACE_OUTBUF_IDX] == NULL) { out_buffers_[PNL_PRELIT_FACE_OUTBUF_IDX] = CreateBuffer(sizeof(Face)); }
    SetDynamicBufferData(&out_buffers_[PNL_PRELIT_FACE_OUTBUF_IDX], (char *) faces.data(), faces.size()*sizeof(Face));
    dirty_buffers_[PNL_PRELIT_FACE_OUTBUF_IDX] = true;
    
    // nodes
    std::vector<Node> nodes = GetSceneNodes(scene_);
    if (out_buffers_[PNL_NODE_OUTBUF_IDX] == NULL) { out_buffers_[PNL_NODE_OUTBUF_IDX] = CreateBuffer(sizeof(Node)); }
    SetDynamicBufferData(&out_buffers_[PNL_NODE_OUTBUF_IDX], (char *) nodes.data(), nodes.size()*sizeof(Node));
    dirty_buffers_[PNL_NODE_OUTBUF_IDX] = true;
    
    // node model ids
    std::vector<uint32_t> nodemodelids = GetSceneNodeModelIDs(scene_);
    if (out_buffers_[PNL_NODEMODELID_OUTBUF_IDX] == NULL) { out_buffers_[PNL_NODEMODELID_OUTBUF_IDX] = CreateBuffer(sizeof(uint32_t)); }
    SetDynamicBufferData(&out_buffers_[PNL_NODEMODELID_OUTBUF_IDX], (char *) nodemodelids.data(), nodemodelids.size()*sizeof(uint32_t));
    dirty_buffers_[PNL_NODEMODELID_OUTBUF_IDX] = true;
    
    // node vertex links
    std::vector<NodeVertexLink> nvlinks = GetSceneNVLinks(scene_);
    if (out_buffers_[PNL_NODEVERTEXLNK_OUTBUF_IDX] == NULL) { out_buffers_[PNL_NODEVERTEXLNK_OUTBUF_IDX] = CreateBuffer(sizeof(NodeVertexLink)); }
    SetDynamicBufferData(&out_buffers_[PNL_NODEVERTEXLNK_OUTBUF_IDX], (char *) nvlinks.data(), nvlinks.size()*sizeof(NodeVertexLink));
    dirty_buffers_[PNL_NODEVERTEXLNK_OUTBUF_IDX] = true;
    
    // model transforms
    std::vector<ModelTransform> modeltrans = GetSceneModelTransforms(scene_);
    if (out_buffers_[PNL_MODELTRANS_OUTBUF_IDX] == NULL) { out_buffers_[PNL_MODELTRANS_OUTBUF_IDX] = CreateBuffer(sizeof(ModelTransform)); }
    SetDynamicBufferData(&out_buffers_[PNL_MODELTRANS_OUTBUF_IDX], (char *) modeltrans.data(), modeltrans.size()*sizeof(ModelTransform));
    dirty_buffers_[PNL_MODELTRANS_OUTBUF_IDX] = true;
    
    // TODO: slice
}

void ViewPanel::InitInBuffers() {
    Panel::InitInBuffers();
    
    // resize in buffers if needed
    unsigned long inbuf_sizes[CPT_NUM_OUTBUFS];
    inbuf_sizes[CPT_COMPCOMPVERTEX_OUTBUF_IDX] = sizeof(Vertex) * (compiled_buffer_key_indices_[CBKI_V_SIZE_IDX]);
    inbuf_sizes[CPT_COMPCOMPFACE_OUTBUF_IDX] = sizeof(Face) * (compiled_buffer_key_indices_[CBKI_F_SIZE_IDX]);
    inbuf_sizes[CPT_COMPCOMPEDGE_OUTBUF_IDX] = sizeof(vec_int2) * (compiled_buffer_key_indices_[CBKI_E_SIZE_IDX]);
    inbuf_sizes[CPT_COMPMODELVERTEX_OUTBUF_IDX] = sizeof(Vertex) * NumSceneVertices(scene_); // TODO: + controls vertices
    inbuf_sizes[CPT_COMPMODELNODE_OUTBUF_IDX] = sizeof(Node) * NumSceneNodes(scene_);

    for (int i = 0; i < CPT_NUM_OUTBUFS; i++) {
        in_buffers_[i] = (Buffer *) malloc(sizeof(Buffer) + inbuf_sizes[i]);
        in_buffers_[i]->capacity = inbuf_sizes[i];
        in_buffers_[i]->size = inbuf_sizes[i];
    }
}

void ViewPanel::InitExtraBuffers() {
    Panel::InitExtraBuffers();
    
    // scene faces
    std::vector<Face> scfaces = GetSceneFaces(scene_);
    if (extra_buffers_[PNL_SCFACE_XBUF] == NULL) { extra_buffers_[PNL_SCFACE_XBUF] = CreateBuffer(sizeof(Face)); }
    SetDynamicBufferData(&extra_buffers_[PNL_SCFACE_XBUF], (char *) scfaces.data(), scfaces.size()*sizeof(Face));
    dirty_extra_buffers_[PNL_SCFACE_XBUF] = true;
    
    // TODO: control face
    
    // scene edges
    std::vector<vec_int2> scedges = GetSceneEdges(scene_);
    if (extra_buffers_[PNL_SCEDGE_XBUF] == NULL) { extra_buffers_[PNL_SCEDGE_XBUF] = CreateBuffer(sizeof(vec_int2)); }
    SetDynamicBufferData(&extra_buffers_[PNL_SCEDGE_XBUF], (char *) scedges.data(), scedges.size()*sizeof(vec_int2));
    dirty_extra_buffers_[PNL_SCEDGE_XBUF] = true;
}

void ViewPanel::SetCamera(Camera *c) {
    if (camera_ != NULL) { delete camera_; }
    camera_ = c;
}

void ViewPanel::EnableLighting(bool enabled) {
    lighting_enabled_ = enabled;
}

void ViewPanel::HandleCameraMovement(float fps) {
    // KEYS
    // find unit vector of xy camera vector
    float magnitude = sqrt(pow(camera_->vector.x, 2)+pow(camera_->vector.y, 2));
    float unit_x = camera_->vector.x/magnitude;
    float unit_y = camera_->vector.y/magnitude;
    
    if (keys_.w) {
        camera_->pos.x += (3.0/fps)*unit_x;
        camera_->pos.y += (3.0/fps)*unit_y;
    }
    if (keys_.a) {
        camera_->pos.y -= (3.0/fps)*unit_x;
        camera_->pos.x += (3.0/fps)*unit_y;
    }
    if (keys_.s) {
        camera_->pos.x -= (3.0/fps)*unit_x;
        camera_->pos.y -= (3.0/fps)*unit_y;
    }
    if (keys_.d) {
        camera_->pos.y += (3.0/fps)*unit_x;
        camera_->pos.x -= (3.0/fps)*unit_y;
    }
    if (keys_.space) {
        camera_->pos.z += (3.0/fps);
    }
    if (keys_.option) {
        camera_->pos.z -= (3.0/fps);
    }

    // MOUSE
    if (keys_.control) {
        //get current camera angles (phi is horizontal and theta is vertical)
        //get the new change based on the amount the mouse moved
        float curr_phi = atan2(camera_->vector.y, camera_->vector.x);
        float phi_change = 100*mouse_.movement.x*(M_PI/180); // TODO: change arbitrary sensitivity (0.1)
        
        float curr_theta = acos(camera_->vector.z);
        float theta_change = 100*mouse_.movement.y*(M_PI/180);
        
        //get new phi and theta angles
        float new_phi = curr_phi + phi_change;
        float new_theta = curr_theta + theta_change;
        //set the camera "pointing" vector to spherical -> cartesian
        camera_->vector.x = sin(new_theta)*cos(new_phi);
        camera_->vector.y = sin(new_theta)*sin(new_phi);
        camera_->vector.z = cos(new_theta);
        //set the camera perpendicular "up" vector the same way but adding pi/2 to theta
        camera_->up_vector.x = sin(new_theta-M_PI_2)*cos(new_phi);
        camera_->up_vector.y = sin(new_theta-M_PI_2)*sin(new_phi);
        camera_->up_vector.z = cos(new_theta-M_PI_2);
    }
    
    SetBufferElement(out_buffers_[PNL_CAMERA_OUTBUF_IDX], 0, sizeof(Camera), (char *) camera_);
    dirty_buffers_[PNL_CAMERA_OUTBUF_IDX] = true;
}
