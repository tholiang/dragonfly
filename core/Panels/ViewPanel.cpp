#include "ViewPanel.h"

ViewPanel::ViewPanel(vec_float4 borders, Scene *scene) : Panel(borders, scene) {
    type_ = PanelType::View;

    camera_ = new Camera();
    elements_.faces = true;
    elements_.light = true;
}

ViewPanel::~ViewPanel() {
    
}

void ViewPanel::Update() {
    Panel::Update();
}

void ViewPanel::HandleInput() {
    HandleCameraMovement();
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

    // lights
    std::vector<SimpleLight> lights = scene_->GetSimpleLights();
    if (out_buffers_[PNL_LIGHT_OUTBUF_IDX] == NULL) { out_buffers_[PNL_LIGHT_OUTBUF_IDX] = CreateBuffer(sizeof(SimpleLight)); }
    SetDynamicBufferData(&out_buffers_[PNL_LIGHT_OUTBUF_IDX], (char *) lights.data(), scene_->NumLights()*sizeof(SimpleLight));
    
    // prelit face
    std::vector<Face> faces = GetSceneFaces(scene_);
    if (out_buffers_[PNL_PRELIT_FACE_OUTBUF_IDX] == NULL) { out_buffers_[PNL_PRELIT_FACE_OUTBUF_IDX] = CreateBuffer(sizeof(Face)); }
    SetDynamicBufferData(&out_buffers_[PNL_PRELIT_FACE_OUTBUF_IDX], (char *) faces.data(), faces.size()*sizeof(Face));
    
    // nodes
    std::vector<Node> nodes = GetSceneNodes(scene_);
    if (out_buffers_[PNL_NODE_OUTBUF_IDX] == NULL) { out_buffers_[PNL_NODE_OUTBUF_IDX] = CreateBuffer(sizeof(Node)); }
    SetDynamicBufferData(&out_buffers_[PNL_NODE_OUTBUF_IDX], (char *) nodes.data(), nodes.size()*sizeof(Node));
    
    // node model ids
    std::vector<uint32_t> nodemodelids = GetSceneNodeModelIDs(scene_);
    if (out_buffers_[PNL_NODEMODELID_OUTBUF_IDX] == NULL) { out_buffers_[PNL_NODEMODELID_OUTBUF_IDX] = CreateBuffer(sizeof(uint32_t)); }
    SetDynamicBufferData(&out_buffers_[PNL_NODEMODELID_OUTBUF_IDX], (char *) nodemodelids.data(), nodemodelids.size()*sizeof(uint32_t));
    
    // node vertex links
    std::vector<NodeVertexLink> nvlinks = GetSceneNVLinks(scene_);
    if (out_buffers_[PNL_NODEVERTEXLNK_OUTBUF_IDX] == NULL) { out_buffers_[PNL_NODEVERTEXLNK_OUTBUF_IDX] = CreateBuffer(sizeof(NodeVertexLink)); }
    SetDynamicBufferData(&out_buffers_[PNL_NODEVERTEXLNK_OUTBUF_IDX], (char *) nvlinks.data(), nvlinks.size()*sizeof(NodeVertexLink));
    
    // model transforms
    std::vector<ModelTransform> modeltrans = GetSceneModelTransforms(scene_);
    if (out_buffers_[PNL_MODELTRANS_OUTBUF_IDX] == NULL) { out_buffers_[PNL_MODELTRANS_OUTBUF_IDX] = CreateBuffer(sizeof(ModelTransform)); }
    SetDynamicBufferData(&out_buffers_[PNL_MODELTRANS_OUTBUF_IDX], (char *) modeltrans.data(), modeltrans.size()*sizeof(ModelTransform));
    
    // TODO: slice
}

void ViewPanel::InitExtraBuffers() {
    Panel::InitExtraBuffers();
    
    // scene faces
    std::vector<Face> scfaces = GetSceneFaces(scene_);
    if (extra_buffers_[PNL_SCFACE_XBUF] == NULL) { extra_buffers_[PNL_SCFACE_XBUF] = CreateBuffer(sizeof(Face)); }
    SetDynamicBufferData(&extra_buffers_[PNL_SCFACE_XBUF], (char *) scfaces.data(), scfaces.size()*sizeof(Face));
    
    // TODO: control face
    
    // scene edges
    std::vector<vec_int2> scedges = GetSceneEdges(scene_);
    if (extra_buffers_[PNL_SCEDGE_XBUF] == NULL) { extra_buffers_[PNL_SCEDGE_XBUF] = CreateBuffer(sizeof(vec_int2)); }
    SetDynamicBufferData(&extra_buffers_[PNL_SCEDGE_XBUF], (char *) scedges.data(), scedges.size()*sizeof(vec_int2));
}

void ViewPanel::SetCamera(Camera *c) {
    if (camera_ != NULL) { delete camera_; }
    camera_ = c;
}

void ViewPanel::EnableLighting(bool enabled) {
    lighting_enabled_ = enabled;
}

void ViewPanel::HandleCameraMovement() {
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
        float phi_change = 0.1*mouse_.movement.x*(M_PI/180); // TODO: change arbitrary sensitivity (0.1)
        
        float curr_theta = acos(camera_->vector.z);
        float theta_change = 0.1*mouse_.movement.y*(M_PI/180);
        
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
}
