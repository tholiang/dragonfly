//
//  Scheme.cpp
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#include "SchemeController.h"
#include "../Pipelines/ComputePipeline.h"

using namespace DragonflyUtils;

Scheme::Scheme() {
    UI_start_.x = 0;
    UI_start_.y = 20;

    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

Scheme::~Scheme() {
    for (int i = 0; i < controls_models_.size(); i++) {
        delete controls_models_[i];
    }
}

SchemeType Scheme::GetType() {
    return type;
}

void Scheme::Update() {
    HandleCameraMovement();
    SetControlsBasis();
    MoveControlsModels();
    
    UpdateUIVars();
}

void Scheme::SetController(SchemeController *sc) {
    controller_ = sc;
}

void Scheme::SetCamera(Camera *camera) {
    camera_ = camera;
    
    vec_float3 behind_camera;
    behind_camera.x = camera_->pos.x - camera_->vector.x*10;
    behind_camera.y = camera_->pos.y - camera_->vector.y*10;
    behind_camera.z = camera_->pos.z - camera_->vector.z*10;
    controls_basis_.pos = behind_camera;
}

void Scheme::SetScene(Scene *scene) {
    scene_ = scene;
    
    CalculateCounts();
    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

void Scheme::HandleCameraMovement() {
    // find unit vector of xy camera vector
    float magnitude = sqrt(pow(camera_->vector.x, 2)+pow(camera_->vector.y, 2));
    float unit_x = camera_->vector.x/magnitude;
    float unit_y = camera_->vector.y/magnitude;
    
    if (keypresses_.w) {
        camera_->pos.x += (3.0/fps)*unit_x;
        camera_->pos.y += (3.0/fps)*unit_y;
    }
    if (keypresses_.a) {
        camera_->pos.y -= (3.0/fps)*unit_x;
        camera_->pos.x += (3.0/fps)*unit_y;
    }
    if (keypresses_.s) {
        camera_->pos.x -= (3.0/fps)*unit_x;
        camera_->pos.y -= (3.0/fps)*unit_y;
    }
    if (keypresses_.d) {
        camera_->pos.y += (3.0/fps)*unit_x;
        camera_->pos.x -= (3.0/fps)*unit_y;
    }
    if (keypresses_.space) {
        camera_->pos.z += (3.0/fps);
    }
    if (keypresses_.option) {
        camera_->pos.z -= (3.0/fps);
    }
}

void Scheme::Undo() {
    if (!past_actions.empty()) {
        UserAction *action = past_actions.back();
        past_actions.pop_back();
        action->Undo();
        delete action;
        
        CalculateCounts();
        should_reset_empty_buffers = true;
        should_reset_static_buffers = true;
    }
}

bool Scheme::ClickOnScene(vec_float2 loc) {
    int pixelX = window_width_ * (loc.x+1)/2;
    int pixelY = window_height_ * (loc.y+1)/2;
    
    if (pixelX < UI_start_.x || pixelX > UI_start_.x + window_width_) {
        return false;
    }
    
    if (pixelY < UI_start_.y || pixelY > UI_start_.y + window_height_) {
        return false;
    }
    
    return true;
}

std::pair<int,float> Scheme::ControlModelClicked(vec_float2 loc) {
    if (computed_compiled_faces_ == NULL || computed_compiled_vertices_ == NULL || computed_key_indices_ == NULL) {
        return std::make_pair(-1, -1);
    }
    
    // for calculating if a point is in a triangle
    float d1, d2, d3;
    bool has_neg, has_pos;
    
    // to return
    float minZ = -1;
    int clickedIdx = -1;
    
    int fid = 0; // fid relative to control models
    for (int mid = 0; mid < controls_models_.size(); mid++) {
        Model *cm = controls_models_[mid];
        int fid_end = fid + cm->NumFaces();
        for (; fid < fid_end; fid++) {
            // get face from kernel calculated array
            // control faces found after scene faces
            Face face = computed_compiled_faces_[fid+computed_key_indices_->compiled_face_control_start];
            
            // get projected vertices
            // projected vertices found after scene vertices
            Vertex v1 = computed_compiled_vertices_[face.vertices[0]];
            Vertex v2 = computed_compiled_vertices_[face.vertices[1]];
            Vertex v3 = computed_compiled_vertices_[face.vertices[2]];
            
            // if click is in triangle, set selected if lower than previous minimum
            if (InTriangle(loc, v1, v2, v3)) {
                float z = WeightedZ(loc, v1, v2, v3);
                if (minZ == -1 || z < minZ) {
                    minZ = z;
                    clickedIdx = mid;
                }
            }
        }
    }
    
    return std::make_pair(clickedIdx, minZ);
}

std::pair<int, float> Scheme::UIElementClicked(vec_float2 loc) {
    if (computed_compiled_faces_ == NULL || computed_compiled_vertices_ == NULL || computed_key_indices_ == NULL) {
        return std::make_pair(-1, -1);
    }

    // for calculating if a point is in a triangle
    float d1, d2, d3;
    bool has_neg, has_pos;
    
    // to return
    float minZ = -1;
    int clickedIdx = -1;
    
    int fid = 0; // fid relative to ui elements
    for (int eid = 0; eid < ui_elements_.size(); eid++) {
        UIElement *e = ui_elements_[eid];
        int fid_end = fid + e->NumFaces();
        for (; fid < fid_end; fid++) {
            Face face = computed_compiled_faces_[fid];
            Vertex v1 = computed_compiled_vertices_[face.vertices[0]];
            Vertex v2 = computed_compiled_vertices_[face.vertices[1]];
            Vertex v3 = computed_compiled_vertices_[face.vertices[2]];
            
            // if click is in triangle, set selected if lower than previous minimum
            if (InTriangle(loc, v1, v2, v3)) {
                float z = WeightedZ(loc, v1, v2, v3);
                if (minZ == -1 || z < minZ) {
                    minZ = z;
                    clickedIdx = eid;
                }
            }
        }
    }
    
    return std::make_pair(clickedIdx, minZ);
}

void Scheme::SetBufferContents(CompiledBufferKeyIndices *cki, Vertex *ccv, Face *ccf, Vertex *cmv, Node *cmn) {
    computed_key_indices_ = cki;
    computed_compiled_vertices_ = ccv;
    computed_compiled_faces_ = ccf;
    computed_model_vertices_ = cmv;
    computed_model_nodes_ = cmn;
}

void Scheme::MakeRect(int x, int y, int w, int h, int z, vec_float4 color) {
    UIElement *elem = new UIElement();
    elem->MakeVertex(0, 0, 0);
    elem->MakeVertex(w, 0, 0);
    elem->MakeVertex(0, h, 0);
    elem->MakeVertex(w, h, 0);
    elem->MakeFace(0, 1, 2, color);
    elem->MakeFace(1, 2, 3, color);
    ui_elements_.push_back(elem);
    
    UIElementTransform uni;
    uni.position = vec_make_int3(x, y, z);
    uni.right = vec_make_float3(1, 0, 0);
    uni.up = vec_make_float3(0, 1, 0);
    ui_element_uniforms_.push_back(uni);
    
    CalculateNumUIVertices();
    CalculateNumUIFaces();
    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

void Scheme::MakeHollowBox(int x, int y, int w, int h, int z, int thickness, vec_float4 color) {
    UIElement *elem = new UIElement();
    elem->MakeVertex(0, 0, 0);
    elem->MakeVertex(w, 0, 0);
    elem->MakeVertex(0, thickness, 0);
    elem->MakeVertex(w, thickness, 0);
    elem->MakeFace(0, 1, 2, color);
    elem->MakeFace(1, 2, 3, color);
    
    elem->MakeVertex(0, 0, 0);
    elem->MakeVertex(thickness, 0, 0);
    elem->MakeVertex(0, h, 0);
    elem->MakeVertex(thickness, h, 0);
    elem->MakeFace(4, 5, 6, color);
    elem->MakeFace(5, 6, 7, color);
    
    elem->MakeVertex(0, h-thickness, 0);
    elem->MakeVertex(w, h-thickness, 0);
    elem->MakeVertex(0, h, 0);
    elem->MakeVertex(w, h, 0);
    elem->MakeFace(8, 9, 10, color);
    elem->MakeFace(9, 10, 11, color);
    
    elem->MakeVertex(w-thickness, 0, 0);
    elem->MakeVertex(w, 0, 0);
    elem->MakeVertex(w-thickness, h, 0);
    elem->MakeVertex(w, h, 0);
    elem->MakeFace(12, 13, 14, color);
    elem->MakeFace(13, 14, 15, color);
    ui_elements_.push_back(elem);
    
    UIElementTransform uni;
    uni.position = vec_make_int3(x, y, z);
    uni.right = vec_make_float3(1, 0, 0);
    uni.up = vec_make_float3(0, 1, 0);
    ui_element_uniforms_.push_back(uni);
    
    CalculateNumUIVertices();
    CalculateNumUIFaces();
    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

void Scheme::MakeIsoTriangle(int x, int y, int w, int h, int z, vec_float4 color) {
    UIElement *elem = new UIElement();
    elem->MakeVertex(0, 0, 0);
    elem->MakeVertex(w, 0, 0);
    elem->MakeVertex(w/2, h, 0);
    elem->MakeFace(0, 1, 2, color);
    ui_elements_.push_back(elem);
    
    UIElementTransform uni;
    uni.position = vec_make_int3(x, y, z);
    uni.right = vec_make_float3(1, 0, 0);
    uni.up = vec_make_float3(0, 1, 0);
    ui_element_uniforms_.push_back(uni);
    
    CalculateNumUIVertices();
    CalculateNumUIFaces();
    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

void Scheme::ChangeElementLocation(int eid, int x, int y) {
    UIElementTransform *uni = &ui_element_uniforms_[eid];
    uni->position.x = x;
    uni->position.y = y;
}

void Scheme::DeleteUIElement(int eid) {
    if (eid >= ui_elements_.size()) { return; }

    delete ui_elements_[eid];
    ui_elements_.erase(ui_elements_.begin() + eid);
    ui_element_uniforms_.erase(ui_element_uniforms_.begin() + eid);

    CalculateNumUIVertices();
    CalculateNumUIFaces();
    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

void Scheme::ChangeRectDim(int eid, int w, int h) {
    UIElement *elem = ui_elements_[eid];
    UIVertex *v2 = elem->GetVertex(1);
    v2->x = w;
    UIVertex *v3 = elem->GetVertex(2);
    v3->y = h;
    UIVertex *v4 = elem->GetVertex(3);
    v4->x = w;
    v4->y = h;
}

void Scheme::EnableInput(bool enabled) {
    input_enabled = enabled;
}

bool Scheme::IsInputEnabled() {
    return input_enabled;
}

void Scheme::EnableLighting(bool enabled) {
    lighting_enabled = enabled;
}

void Scheme::HandleMouseMovement(float x, float y, float dx, float dy) {
    if (input_enabled && keypresses_.control) {
        //get current camera angles (phi is horizontal and theta is vertical)
        //get the new change based on the amount the mouse moved
        float curr_phi = atan2(camera_->vector.y, camera_->vector.x);
        float phi_change = x_sens_*dx*(M_PI/180);
        
        float curr_theta = acos(camera_->vector.z);
        float theta_change = y_sens_*dy*(M_PI/180);
        
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
 
void Scheme::HandleKeyPresses(int key, bool keydown) {
    if (input_enabled) {
        switch (key) {
            case 119:
                keypresses_.w = keydown;
                break;
            case 97:
                keypresses_.a = keydown;
                break;
            case 115:
                keypresses_.s = keydown;
                break;
            case 100:
                keypresses_.d = keydown;
                break;
            case 32:
                keypresses_.space = keydown;
                break;
            case 122:
                // z
                if (keypresses_.command && keydown) Undo();
                break;
            case 1073742049:
                keypresses_.shift = keydown;
                break;
            case 1073742048:
                keypresses_.control = keydown;
                break;
            case 1073742054:
                keypresses_.option = keydown;
                break;
            case 1073742055:
                keypresses_.command = keydown;
                break;
            default:
                break;
        }
    }
}

void Scheme::HandleMouseDown(vec_float2 loc, bool left) {
    loc.x = ((float) loc.x / (float) window_width_)*2 - 1;
    loc.y = -(((float) loc.y / (float) window_height_)*2 - 1);
    if (input_enabled && ClickOnScene(loc)) {
        click_loc_ = loc;
        
        if (left) {
            HandleSelection(click_loc_);
            left_mouse_down_ = true;
        } else {
            right_mouse_down_ = true;
        }
    }
}

void Scheme::HandleMouseUp(vec_float2 loc, bool left) {
    if (left) {
        left_mouse_down_ = false;
    } else {
        right_mouse_down_ = false;
    }
}

void Scheme::MoveControlsModels() {
    for (int i = 0; i < controls_model_uniforms_.size(); i++) {
        controls_model_uniforms_[i].rotate_origin = controls_basis_.pos;
        //controls_model_uniforms_[i].b = controls_basis_;
        controls_model_uniforms_[i].b = TranslateBasis(&controls_model_default_bases_[i], &controls_basis_);
    }
    
    float camtocontrols = dist3to3(camera_->pos, controls_basis_.pos);
    float scale = 0.5+camtocontrols/4;
    
    for (int i = 0; i < controls_models_.size(); i++) {
        ModelTransform *mu = &controls_model_uniforms_[i];
        // x
        float currmagx = Magnitude(mu->b.x);
        mu->b.x.x *= scale/currmagx;
        mu->b.x.y *= scale/currmagx;
        mu->b.x.z *= scale/currmagx;
        // y
        float currmagy = Magnitude(mu->b.y);
        mu->b.y.x *= scale/currmagy;
        mu->b.y.y *= scale/currmagy;
        mu->b.y.z *= scale/currmagy;
        // z
        float currmagz = Magnitude(mu->b.z);
        mu->b.z.x *= scale/currmagz;
        mu->b.z.y *= scale/currmagz;
        mu->b.z.z *= scale/currmagz;
    }
}

void Scheme::SetControlsBasis() {
    
}

void Scheme::CreateNewModel() {
    scene_->CreateNewModel();
    
    CalculateCounts();
    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

void Scheme::NewModelFromFile(std::string path) {
    scene_->NewModelFromFile(path);
    
    CalculateCounts();
    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

void Scheme::NewModelFromPointData(std::string path) {
    scene_->NewModelFromPointData(path);
    
    CalculateCounts();
    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

void Scheme::UpdateUIVars() {
    window_width_ = ImGui::GetIO().DisplaySize.x;
    window_height_ = ImGui::GetIO().DisplaySize.y;
    aspect_ratio_ = (float) window_width_/ (float) window_height_;
    fps = ImGui::GetIO().Framerate;
    
    window_attributes.screen_width = window_width_;
    window_attributes.screen_height = window_height_;
    
    camera_->FOV = {M_PI_2, 2*(atanf((float) window_height_/(float) window_width_))};
}

bool Scheme::DidScreenSizeChange() {
    if (window_width_ != prev_width || window_height_ != prev_height) {
        prev_width = window_width_;
        prev_height = window_height_;
        return true;
    }
    
    return false;
}

void Scheme::MainWindow() {
    ImGui::SetNextWindowPos(ImVec2(UI_start_.x, UI_start_.y));
    ImGui::SetNextWindowSize(ImVec2(window_width_, window_height_));
    ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.0f, 0.0f, 0.0f, 0.0f));
    ImGui::Begin("main", &show_UI, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoResize);
    
    // Display FPS
    fps = ImGui::GetIO().Framerate;
    
    ImGui::SetCursorPos(ImVec2(5, 10));
    ImGui::Text("%.1f FPS", fps);
    ImGui::PopStyleColor();
    
    ImGui::End();
}

WindowAttributes *Scheme::GetWindowAttributes() {
    return &window_attributes;
}

std::vector<uint32_t> Scheme::GetSelectedVertices() {
    return selected_vertices;
}

int Scheme::GetSelectedNode() {
    return selected_node_;
}

vec_float4 Scheme::GetEditWindow() {
    vec_float4 window;
    window.x = 0;
    window.y = float(-2*UI_start_.y) / window_height_;
    window.z = 1;
    window.w = float(window_height_ - UI_start_.y)/window_height_;
    
    return window;
}

void Scheme::SaveSceneToFolder(std::string path) {
    scene_->SaveToFolder(path);
}

void Scheme::SetResetEmptyBuffers(bool set) {
    should_reset_empty_buffers = set;
}

void Scheme::SetResetStaticBuffers(bool set) {
    should_reset_static_buffers = set;
}

bool Scheme::ShouldResetEmptyBuffers() {
    return should_reset_empty_buffers;
}

bool Scheme::ShouldResetStaticBuffers() {
    return should_reset_static_buffers;
}

bool Scheme::LightingEnabled() {
    return lighting_enabled;
}

void Scheme::CalculateCounts() {
    CalculateNumSceneVertices();
    CalculateNumSceneFaces();
    CalculateNumSceneNodes();
    CalculateNumSceneDots();
    CalculateNumSceneLines();
    CalculateNumControlsVertices();
    CalculateNumControlsFaces();
    CalculateNumControlsNodes();
    CalculateNumUIVertices();
    CalculateNumUIFaces();
}

void Scheme::CalculateNumSceneVertices() {
    int sum = 0;
    for (int i = 0; i < scene_->NumModels(); i++) {
        sum += scene_->GetModel(i)->NumVertices();
    }
    scene_vertex_length_ = sum;
}

void Scheme::CalculateNumSceneFaces() {
    int sum = 0;
    for (int i = 0; i < scene_->NumModels(); i++) {
        sum += scene_->GetModel(i)->NumFaces();
    }
    scene_face_length_ = sum;
}

void Scheme::CalculateNumSceneNodes() {
    int sum = 0;
    for (int i = 0; i < scene_->NumModels(); i++) {
        sum += scene_->GetModel(i)->NumNodes();
    }
    scene_node_length_ = sum;
}

void Scheme::CalculateNumSceneDots() {
    int sum = 0;
    for (int i = 0; i < scene_->NumSlices(); i++) {
        sum += scene_->GetSlice(i)->NumDots();
    }
    scene_dot_length_ = sum;
}

void Scheme::CalculateNumSceneLines() {
    int sum = 0;
    for (int i = 0; i < scene_->NumSlices(); i++) {
        sum += scene_->GetSlice(i)->NumLines();
    }
    scene_line_length_ = sum;
}

void Scheme::CalculateNumControlsVertices() {
    int sum = 0;
    for (int i = 0; i < controls_models_.size(); i++) {
        sum += controls_models_[i]->NumVertices();
    }
    controls_vertex_length_ = sum;
}

void Scheme::CalculateNumControlsFaces() {
    int sum = 0;
    for (int i = 0; i < controls_models_.size(); i++) {
        sum += controls_models_[i]->NumFaces();
    }
    controls_face_length_ = sum;
}

void Scheme::CalculateNumControlsNodes() {
    int sum = 0;
    for (int i = 0; i < controls_models_.size(); i++) {
        sum += controls_models_[i]->NumNodes();
    }
    controls_node_length_ = sum;
}

void Scheme::CalculateNumUIFaces() {
    int sum = 0;
    for (int i = 0; i < ui_elements_.size(); i++) {
        sum += ui_elements_[i]->NumFaces();
    }
    ui_face_length_ = sum;
}

void Scheme::CalculateNumUIVertices() {
    int sum = 0;
    for (int i = 0; i < ui_elements_.size(); i++) {
        sum += ui_elements_[i]->NumVertices();
    }
    ui_vertex_length_ = sum;
}

std::pair<int, int> Scheme::GetModelVertexIdx(int compiled_idx) {
    int cur_model_vertex_end = 0;
    for (int mid = 0; mid < scene_->NumModels(); mid++) {
        int next_model_vertex_end = cur_model_vertex_end+scene_->GetModel(mid)->NumVertices();
        
        if (compiled_idx < next_model_vertex_end) {
            return std::make_pair(mid, compiled_idx - cur_model_vertex_end);
        }
        
        cur_model_vertex_end = next_model_vertex_end;
    }
    
    return std::make_pair(-1, -1);
}

std::pair<int, int> Scheme::GetModelFaceIdx(int compiled_idx) {
    int cur_model_face_end = 0;
    for (int mid = 0; mid < scene_->NumModels(); mid++) {
        int next_model_face_end = cur_model_face_end+scene_->GetModel(mid)->NumFaces();
        
        if (compiled_idx < next_model_face_end) {
            return std::make_pair(mid, compiled_idx - cur_model_face_end);
        }
        
        cur_model_face_end = next_model_face_end;
    }
    
    return std::make_pair(-1, -1);
}

std::pair<int, int> Scheme::GetModelNodeIdx(int node_idx) {
    int cur_model_node_end = 0;
    for (int mid = 0; mid < scene_->NumModels(); mid++) {
        int next_model_node_end = cur_model_node_end+scene_->GetModel(mid)->NumNodes();
        
        if (node_idx < next_model_node_end) {
            return std::make_pair(mid, node_idx - cur_model_node_end);
        }
        
        cur_model_node_end = next_model_node_end;
    }
    
    return std::make_pair(-1, -1);
}

int Scheme::GetCompiledVertexIdx(int model_idx, int vertex_idx) {
    int cur_model_vertex_start = 0;
    for (int mid = 0; mid < scene_->NumModels(); mid++) {
        if (mid == model_idx) {
            return cur_model_vertex_start + vertex_idx;
        }
        cur_model_vertex_start += scene_->GetModel(mid)->NumVertices();
    }
    
    return -1;
}

int Scheme::GetCompiledFaceIdx(int model_idx, int face_idx) {
    int cur_model_face_start = 0;
    for (int mid = 0; mid < scene_->NumModels(); mid++) {
        if (mid == model_idx) {
            return cur_model_face_start + face_idx;
        }
        cur_model_face_start += scene_->GetModel(mid)->NumFaces();
    }
    
    return -1;
}

int Scheme::GetArrayNodeIdx(int model_idx, int node_idx) {
    int cur_model_node_start = 0;
    for (int mid = 0; mid < scene_->NumModels(); mid++) {
        if (mid == model_idx) {
            return cur_model_node_start + node_idx;
        }
        cur_model_node_start += scene_->GetModel(mid)->NumNodes();
    }
    
    return -1;
}

Camera * Scheme::GetCamera() {
    return camera_;
}

Scene * Scheme::GetScene() {
    return scene_;
}

/*std::vector<Model *> *Scheme::GetModels() {
    return scene_->GetModels();
}

std::vector<ModelTransform> *Scheme::GetModelUniforms() {
    return scene_->GetAllModelUniforms();
}

std::vector<Slice *> *Scheme::GetSlices() {
    return scene_->GetSlices();
}

std::vector<ModelTransform> *Scheme::GetSliceUniforms() {
    return scene_->GetAllSliceUniforms();
}

std::vector<Model *> * Scheme::GetControlsModels() {
    return &controls_models_;
}

std::vector<ModelTransform> * Scheme::GetControlsModelUniforms() {
    return &controls_model_uniforms_;
}

std::vector<UIElement *> *Scheme::GetUIElements() {
    return &ui_elements_;
}

std::vector<UIElementTransform> *Scheme::GetUIElementUniforms() {
    return &ui_element_uniforms_;
}*/

unsigned long Scheme::NumSceneModels() { return scene_->NumModels(); }
unsigned long Scheme::NumSceneVertices() { return scene_vertex_length_; }
unsigned long Scheme::NumSceneFaces() { return scene_face_length_; }
unsigned long Scheme::NumSceneNodes() { return scene_node_length_; }
unsigned long Scheme::NumSceneLights() { return scene_->NumLights(); }
unsigned long Scheme::NumSceneSlices() { return scene_->NumSlices(); }
unsigned long Scheme::NumSceneDots() { return scene_dot_length_; }
unsigned long Scheme::NumSceneLines() { return scene_line_length_; }
unsigned long Scheme::NumControlsModels() { return controls_models_.size(); }
unsigned long Scheme::NumControlsVertices() { return controls_vertex_length_; }
unsigned long Scheme::NumControlsFaces() { return controls_face_length_; }
unsigned long Scheme::NumControlsNodes() { return controls_node_length_; }
unsigned long Scheme::NumUIElements() { return ui_elements_.size(); }
unsigned long Scheme::NumUIFaces() { return ui_face_length_; }
unsigned long Scheme::NumUIVertices() { return ui_vertex_length_; }

bool Scheme::ShouldRenderFaces() { return should_render.faces; }
bool Scheme::ShouldRenderEdges() { return should_render.edges; }
bool Scheme::ShouldRenderVertices() { return should_render.vertices; }
bool Scheme::ShouldRenderNodes() { return should_render.nodes; }
bool Scheme::ShouldRenderSlices() { return should_render.slices; }


void Scheme::SetSceneFaceBuffer(Face *buf, unsigned long vertex_start) {
    // track the current face index in the buffer
    unsigned long cur_fid = 0;
    
    // track the starting vertex index of the current model in the compiled buffer
    // vertex ids are local to the model - the buffer vertex ids will line up if the models are iterated in the same order
    unsigned long cur_vertex_start = vertex_start;
    
    for (int i = 0; i < scene_->NumModels(); i++) { // iterate through models
        Model *m = scene_->GetModel(i); // get current model
        for (int j = 0; j < m->NumFaces(); j++) { // iterate through current models faces
            // copy face
            Face face = *m->GetFace(j);
            // add current vertex start to original face vids (which are local to the model)
            face.vertices[0] += cur_vertex_start;
            face.vertices[1] += cur_vertex_start;
            face.vertices[2] += cur_vertex_start;
            buf[cur_fid++] = face;
        }
        
        // increment the current vertex start to the next model
        cur_vertex_start += m->NumVertices();
    }
}

void Scheme::SetSceneEdgeBuffer(vec_int2 *buf, unsigned long vertex_start) {
    // track the current edge index in the buffer
    unsigned long cur_eid = 0;
    
    // track the starting vertex index of the current model in the compiled buffer
    // vertex ids are local to the model - the buffer vertex ids will line up if the models are iterated in the same order
    unsigned long cur_vertex_start = vertex_start;
    
    for (int i = 0; i < scene_->NumModels(); i++) { // iterate through models
        Model *m = scene_->GetModel(i); // get current model
        for (int j = 0; j < m->NumFaces(); j++) { // iterate through current models faces
            // three edges per face
            Face face = *m->GetFace(j);
            // create edges
            // add current vertex starts to original face vids (which are local to the model)
            buf[cur_eid++] = vec_make_int2(face.vertices[0]+cur_vertex_start, face.vertices[1]+cur_vertex_start);
            buf[cur_eid++] = vec_make_int2(face.vertices[1]+cur_vertex_start, face.vertices[2]+cur_vertex_start);
            buf[cur_eid++] = vec_make_int2(face.vertices[2]+cur_vertex_start, face.vertices[0]+cur_vertex_start);
        }
        
        // increment the current vertex start to the next model
        cur_vertex_start += m->NumVertices();
    }
}

void Scheme::SetSceneNodeBuffer(Node *buf) {
    // track the current node index in the buffer
    unsigned long cur_nid = 0;
    
    for (int i = 0; i < scene_->NumModels(); i++) { // iterate through models
        Model *m = scene_->GetModel(i); // get current model
        for (int j = 0; j < m->NumNodes(); j++) { // iterate through current models nodes
            // copy node exactly
            buf[cur_nid++] = *m->GetNode(j);
        }
    }
}

void Scheme::SetSceneNodeModelIDBuffer(uint32_t *buf, unsigned long model_start) {
    // track the current node index in the buffer
    unsigned long cur_nid = 0;
    
    for (int i = 0; i < scene_->NumModels(); i++) { // iterate through models
        Model *m = scene_->GetModel(i); // get current model
        for (int j = 0; j < m->NumNodes(); j++) { // iterate through current models nodes
            // put model index in buffer
            buf[cur_nid++] = i+model_start;
        }
    }
}

void Scheme::SetSceneNodeVertexLinkBuffer(NodeVertexLink *buf, unsigned long node_start) {
    // track the current nvlink index in the buffer
    unsigned long cur_nvlid = 0;
    
    // track the current node in the node buffer
    unsigned long cur_node_start = node_start;
    
    for (int i = 0; i < scene_->NumModels(); i++) { // iterate through models
        Model *m = scene_->GetModel(i); // get current model
        for (int j = 0; j < m->NumVertices()*2; j++) { // iterate through current models nodes
            // copy nvlink
            NodeVertexLink nvlink = *m->GetNodeVertexLink(j);
            // add current node start to original nvlink nids (which are local to the model)
            nvlink.nid += cur_node_start;
            buf[cur_nvlid++] = nvlink;
        }
        
        // increment the current node start to the next model
        cur_node_start += m->NumNodes();
    }
}

void Scheme::SetSceneModelTransformBuffer(ModelTransform *buf) {
    // track the current model id in the buffer
    unsigned long cur_mid = 0;
    
    for (int i = 0; i < scene_->NumModels(); i++) { // iterate through models
        // copy model uniforms into buffer
        buf[cur_mid++] = *scene_->GetModelUniforms(i);
    }
}

void Scheme::SetSceneLightBuffer(SimpleLight *buf) {
    // track the current light id in the buffer
    unsigned long cur_lid = 0;
    
    for (int i = 0; i < scene_->NumLights(); i++) { // iterate through lights
        // copy light into buffer
        Basis *b = scene_->GetLightBasis(i);
        buf[cur_lid++] = scene_->GetLight(i)->ToSimpleLight(*b);
    }
}

void Scheme::SetControlFaceBuffer(Face *buf, unsigned long vertex_start) {
    // track the current face index in the buffer
    unsigned long cur_fid = 0;
    
    // track the starting vertex index of the current model in the compiled buffer
    // vertex ids are local to the model - the buffer vertex ids will line up if the models are iterated in the same order
    unsigned long cur_vertex_start = vertex_start;
    
    for (int i = 0; i < controls_models_.size(); i++) { // iterate through models
        Model *m = controls_models_.at(i); // get current model
        for (int j = 0; j < m->NumFaces(); j++) { // iterate through current models faces
            // copy face
            Face face = *m->GetFace(j);
            // add current vertex start to original face vids (which are local to the model)
            face.vertices[0] += cur_vertex_start;
            face.vertices[1] += cur_vertex_start;
            face.vertices[2] += cur_vertex_start;
            buf[cur_fid++] = face;
        }
        
        // increment the current vertex start to the next model
        cur_vertex_start += m->NumVertices();
    }
}

void Scheme::SetControlNodeBuffer(Node *buf) {
    // track the current node index in the buffer
    unsigned long cur_nid = 0;
    
    for (int i = 0; i < controls_models_.size(); i++) { // iterate through models
        Model *m = controls_models_.at(i); // get current model
        for (int j = 0; j < m->NumNodes(); j++) { // iterate through current models nodes
            // copy node exactly
            buf[cur_nid++] = *m->GetNode(j);
        }
    }
}

void Scheme::SetControlNodeModelIDBuffer(uint32_t *buf, unsigned long model_start) {
    // track the current node index in the buffer
    unsigned long cur_nid = 0;
    
    for (int i = 0; i < controls_models_.size(); i++) { // iterate through models
        Model *m = controls_models_.at(i); // get current model
        for (int j = 0; j < m->NumNodes(); j++) { // iterate through current models nodes
            // put model index in buffer
            buf[cur_nid++] = i+model_start;
        }
    }
}

void Scheme::SetControlNodeVertexLinkBuffer(NodeVertexLink *buf, unsigned long node_start) {
    // track the current nvlink index in the buffer
    unsigned long cur_nvlid = 0;
    
    // track the current node in the node buffer
    unsigned long cur_node_start = node_start;
    
    for (int i = 0; i < controls_models_.size(); i++) { // iterate through models
        Model *m = controls_models_.at(i); // get current model
        for (int j = 0; j < m->NumVertices()*2; j++) { // iterate through current models nodes
            // copy nvlink
            NodeVertexLink nvlink = *m->GetNodeVertexLink(j);
            // add current node start to original nvlink nids (which are local to the model)
            nvlink.nid += cur_node_start;
            buf[cur_nvlid++] = nvlink;
        }
        
        // increment the current node start to the next model
        cur_node_start += m->NumNodes();
    }
}

void Scheme::SetControlModelTransformBuffer(ModelTransform *buf) {
    // track the current model id in the buffer
    unsigned long cur_mid = 0;
    
    for (int i = 0; i < controls_models_.size(); i++) { // iterate through models
        // copy model uniforms into buffer
        buf[cur_mid++] = controls_model_uniforms_.at(i);
    }
}

void Scheme::SetSliceDotBuffer(Dot *buf) {
    // track the current dot id in the buffer
    unsigned long cur_did = 0;
    
    for (int i = 0; i < scene_->NumSlices(); i++) { // iterate through slices
        Slice *s = scene_->GetSlice(i); // get current slice
        for (int j = 0; j < s->NumDots(); j++) { // iterate through dots
            // add dot to buffer
            buf[cur_did++] = *s->GetDot(j);
        }
    }
}

void Scheme::SetSliceLineBuffer(vec_int2 *buf, unsigned long dot_start) {
    // track the current line index in the buffer
    unsigned long cur_lid = 0;
    
    // track the starting dot index of the current slice in the compiled buffer
    // dot ids are local to the slice - the buffer dot ids will line up if the slices are iterated in the same order
    unsigned long cur_dot_start = dot_start;
    
    for (int i = 0; i < scene_->NumSlices(); i++) { // iterate through slices
        Slice *s = scene_->GetSlice(i); // get current slice
        for (int j = 0; j < s->NumLines(); j++) { // iterate through current models faces
            // copy line
            Line l = *s->GetLine(j);
            // add dot start to original line dids
            l.d1 += dot_start;
            l.d2 += dot_start;
            
            // TODO: MAYBE CHANGE EDGE/LINE FORMAT
            buf[cur_lid++] = vec_make_int2(l.d1, l.d2);
        }
        
        // increment the current dot start to the next model
        cur_dot_start += s->NumDots();
    }
}

void Scheme::SetSliceAttributesBuffer(SliceAttributes *buf) {
    // track the current slice index in the buffer
    unsigned long cur_sid = 0;
    
    for (int i = 0; i < scene_->NumSlices(); i++) { // iterate through slices
        buf[cur_sid++] = scene_->GetSlice(i)->GetAttributes(); // copy slice attributes
    }
}

void Scheme::SetSliceTransformBuffer(ModelTransform *buf) {
    // track the current slice index in the buffer
    unsigned long cur_sid = 0;
    
    for (int i = 0; i < scene_->NumSlices(); i++) { // iterate through slices
        buf[cur_sid++] = *scene_->GetSliceUniforms(i); // copy slice transform
    }
}

void Scheme::SetUIFaceBuffer(Face *buf, unsigned long vertex_start) {
    // track the current face index in the buffer
    unsigned long cur_fid = 0;
    
    // track the starting vertex index of the current element in the compiled buffer
    // vertex ids are local to the element - the buffer vertex ids will line up if the elements are iterated in the same order
    unsigned long cur_vertex_start = vertex_start;
    
    for (int i = 0; i < ui_elements_.size(); i++) { // iterate through elements
        UIElement *e = ui_elements_.at(i); // get current element
        for (int j = 0; j < e->NumFaces(); j++) { // iterate through current elements faces
            UIFace *uif = e->GetFace(j); // get ui face
            
            Face face; // create new face - have to translate UIFace to normal Face
            face.color = uif->color; // copy color over
            // add current vertex start to original face vids (which are local to the model)
            face.vertices[0] = uif->vertices[0] + cur_vertex_start;
            face.vertices[1] = uif->vertices[1] + cur_vertex_start;
            face.vertices[2] = uif->vertices[2] + cur_vertex_start;
            // lighting values don't matter - lighting only calculated for scene models
            
            buf[cur_fid++] = face;
        }
        
        // increment the current vertex start to the next element
        cur_vertex_start += e->NumVertices();
    }
}

void Scheme::SetUIVertexBuffer(UIVertex *buf) {
    // track the current vertex index in the buffer
    unsigned long cur_vid = 0;
    
    for (int i = 0; i < ui_elements_.size(); i++) { // iterate through elements
        UIElement *e = ui_elements_.at(i); // get current element
        for (int j = 0; j < e->NumVertices(); j++) { // iterate through current elements faces
            buf[cur_vid++] = *e->GetVertex(j); // copy vertex
        }
    }
}

void Scheme::SetUIElementIDBuffer(uint32_t *buf) {
    // track the current element index in the buffer
    unsigned long cur_eid = 0;
    
    for (int i = 0; i < ui_elements_.size(); i++) { // iterate through elements
        UIElement *e = ui_elements_.at(i); // get current element
        for (int j = 0; j < e->NumVertices(); j++) { // iterate through current elements faces
            buf[cur_eid++] = i; // set element id
        }
    }
}

void Scheme::SetUITransformBuffer(UIElementTransform *buf) {
    // track the current element index in the buffer
    unsigned long cur_eid = 0;
    
    for (int i = 0; i < ui_elements_.size(); i++) { // iterate through elements
        buf[cur_eid++] = ui_element_uniforms_[i];
    }
}
