//
//  Scheme.mm
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#include "SchemeController.h"

using namespace DragonflyUtils;

Scheme::Scheme() {
    node_render_uniforms_.selected_node = -1;
    
    UI_start_.x = 0;
    UI_start_.y = 20;
}

Scheme::~Scheme() {
    for (int i = 0; i < controls_models_.size(); i++) {
        delete controls_models_[i];
    }
}

SchemeType Scheme::GetType() {
    return type;
}

void Scheme::SetController(SchemeController *sc) {
    controller_ = sc;
}

void Scheme::SetCamera(Camera *camera) {
    camera_ = camera;
    
    simd_float3 behind_camera;
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

void Scheme::SetBufferContents(Vertex *smv, Vertex *smpv, Face *smf, Node *smn, Vertex *smpn, Vertex *cmv, Vertex *cmpv, Face *cmf, Vertex *ssp) {
    scene_models_vertices_ = smv;
    scene_models_projected_vertices_ = smpv;
    scene_models_faces_ = smf;
    scene_models_nodes_ = smn;
    scene_models_projected_nodes_ = smpn;
    control_models_vertices_ = cmv;
    control_models_projected_vertices_ = cmpv;
    control_models_faces_ = cmf;
    scene_slice_plate_vertices_ = ssp;
}

Camera * Scheme::GetCamera() {
    return camera_;
}

Scene * Scheme::GetScene() {
    return scene_;
}

std::vector<Model *> *Scheme::GetModels() {
    return scene_->GetModels();
}

std::vector<ModelUniforms> *Scheme::GetModelUniforms() {
    return scene_->GetAllModelUniforms();
}

std::vector<Slice *> *Scheme::GetSlices() {
    return scene_->GetSlices();
}

std::vector<SliceAttributes> Scheme::GetSliceAttributes() {
    return scene_->GetAllSliceAttributes();
}

std::vector<ModelUniforms> *Scheme::GetSliceUniforms() {
    return scene_->GetAllSliceUniforms();
}

std::vector<Model *> * Scheme::GetControlsModels() {
    return &controls_models_;
}

std::vector<ModelUniforms> * Scheme::GetControlsModelUniforms() {
    return &controls_model_uniforms_;
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

bool Scheme::ClickOnScene(simd_float2 loc) {
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

void Scheme::HandleMouseDown(simd_float2 loc, bool left) {
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

void Scheme::HandleMouseUp(simd_float2 loc, bool left) {
    if (left) {
        left_mouse_down_ = false;
    } else {
        right_mouse_down_ = false;
    }
}

std::pair<int,float> Scheme::ControlModelClicked(simd_float2 loc) {
    float d1, d2, d3;
    bool has_neg, has_pos;
    
    float minZ = -1;
    int clickedIdx = -1;
    
    int fid = 0;
    for (int mid = 0; mid < controls_models_.size(); mid++) {
        Model *cm = controls_models_[mid];
        int fid_end = fid + cm->NumFaces();
        for (; fid < fid_end; fid++) {
            Face face = control_models_faces_[fid];
            Vertex v1 = control_models_projected_vertices_[face.vertices[0]];
            Vertex v2 = control_models_projected_vertices_[face.vertices[1]];
            Vertex v3 = control_models_projected_vertices_[face.vertices[2]];
            
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

void Scheme::MoveControlsModels() {
    for (int i = 0; i < controls_model_uniforms_.size(); i++) {
        controls_model_uniforms_[i].rotate_origin = controls_basis_.pos;
        //controls_model_uniforms_[i].b = controls_basis_;
        controls_model_uniforms_[i].b = TranslateBasis(&controls_model_default_bases_[i], &controls_basis_);
    }
    
    float camtocontrols = dist3to3(camera_->pos, controls_basis_.pos);
    float scale = 0.5+camtocontrols/4;
    
    for (int i = 0; i < controls_models_.size(); i++) {
        ModelUniforms *mu = &controls_model_uniforms_[i];
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
    
    vertex_render_uniforms.screen_ratio = aspect_ratio_;
    node_render_uniforms_.screen_ratio = aspect_ratio_;
    
    camera_->FOV = {M_PI_2, 2*(atanf((float) window_height_/(float) window_width_))};
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

VertexRenderUniforms *Scheme::GetVertexRenderUniforms() {
    return &vertex_render_uniforms;
}

NodeRenderUniforms *Scheme::GetNodeRenderUniforms() {
    return &node_render_uniforms_;
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

unsigned long Scheme::NumSceneVertices() {
    return scene_vertex_length_;
}

unsigned long Scheme::NumSceneFaces() {
    return scene_face_length_;
}

unsigned long Scheme::NumSceneNodes() {
    return scene_node_length_;
}

unsigned long Scheme::NumSceneDots() {
    return scene_dot_length_;
}

unsigned long Scheme::NumSceneLines() {
    return scene_line_length_;
}

unsigned long Scheme::NumControlsVertices() {
    return controls_vertex_length_;
}

unsigned long Scheme::NumControlsFaces() {
    return controls_face_length_;
}

unsigned long Scheme::NumControlsNodes() {
    return controls_node_length_;
}

bool Scheme::ShouldRenderFaces() {
    return should_render.faces;
}

bool Scheme::ShouldRenderEdges() {
    return should_render.edges;
}

bool Scheme::ShouldRenderVertices() {
    return should_render.vertices;
}

bool Scheme::ShouldRenderNodes() {
    return should_render.nodes;
}

bool Scheme::ShouldRenderSlices() {
    return should_render.slices;
}

void Scheme::Update() {
    HandleCameraMovement();
    SetControlsBasis();
    MoveControlsModels();
    
    UpdateUIVars();
}

simd_float4 Scheme::GetEditWindow() {
    simd_float4 window;
    window.x = 0;
    window.y = float(-2*UI_start_.y) / window_height_;
    window.z = 1;
    window.w = float(window_height_ - UI_start_.y)/window_height_;
    
    return window;
}
