//
//  EditModelScheme.m
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#import <Foundation/Foundation.h>
#include "EditModelScheme.h"

using namespace DragonflyUtils;

EditModelScheme::EditModelScheme() {
    type = SchemeType::EditModel;
    
    should_render.faces = true;
    should_render.edges = false;
    should_render.vertices = false;
    should_render.nodes = false;
    
    CreateControlsModels();
}

EditModelScheme::~EditModelScheme() {
    
}

void EditModelScheme::CreateControlsModels() {
    z_arrow = new Arrow(0);
    
    ModelUniforms z_arrow_uniform;
    z_arrow_uniform.position = simd_make_float3(0, 0, 1);
    z_arrow_uniform.rotate_origin = simd_make_float3(0, 0, 1);
    z_arrow_uniform.angle = simd_make_float3(0, 0, 0);
    
    controls_model_uniforms_.push_back(z_arrow_uniform);
    arrow_projections[0] = simd_make_float2(0,0);
    arrow_projections[1] = simd_make_float2(0,1);
    
    controls_models_.push_back(z_arrow);
    
    x_arrow = new Arrow(1, simd_make_float4(0, 1, 0, 1));
    
    ModelUniforms x_arrow_uniform;
    x_arrow_uniform.position = simd_make_float3(0, 0, 1);
    x_arrow_uniform.rotate_origin = simd_make_float3(0, 0, 1);
    x_arrow_uniform.angle = simd_make_float3(M_PI_2, 0, 0);
    
    controls_model_uniforms_.push_back(x_arrow_uniform);
    arrow_projections[2] = simd_make_float2(0,0);
    arrow_projections[3] = simd_make_float2(0,0);
    
    controls_models_.push_back(x_arrow);
    
    y_arrow = new Arrow(2, simd_make_float4(0, 0, 1, 1));
    
    ModelUniforms y_arrow_uniform;
    y_arrow_uniform.position = simd_make_float3(0, 0, 1);
    y_arrow_uniform.rotate_origin = simd_make_float3(0, 0, 1);
    y_arrow_uniform.angle = simd_make_float3(0, -M_PI_2, 0);
    
    controls_model_uniforms_.push_back(y_arrow_uniform);
    arrow_projections[4] = simd_make_float2(0,0);
    arrow_projections[5] = simd_make_float2(1,0);
    
    controls_models_.push_back(y_arrow);
}

void EditModelScheme::HandleMouseUp(simd_float2 loc, bool left) {
    Scheme::HandleMouseUp(loc, left);
    
    if (left) {
        selected_arrow = -1;
    }
    
    if (current_action != NULL) {
        current_action->EndRecording();
        past_actions.push_back(current_action);
        current_action = NULL;
    }
}

bool EditModelScheme::ClickOnScene(simd_float2 loc) {
    int pixelX = window_width_ * (loc.x+1)/2;
    int pixelY = window_height_ * (loc.y+1)/2;
    
    if (pixelX < UI_start_.x || pixelX > UI_start_.x + window_width_ - right_menu_width_) {
        return false;
    }
    
    if (pixelY < UI_start_.y || pixelY > UI_start_.y + window_height_) {
        return false;
    }
    
    return true;
}

std::pair<int, float> EditModelScheme::ModelClicked(simd_float2 loc) {
    float d1, d2, d3;
    bool has_neg, has_pos;
    
    float minZ = -1;
    int clickedIdx = -1;
    
    int fid = 0;
    for (int mid = 0; mid < scene_->NumModels(); mid++) {
        Model *m = scene_->GetModel(mid);
        int fid_end = fid + m->NumFaces();
        for (; fid < fid_end; fid++) {
            Face face = scene_models_faces_[fid];
            Vertex v1 = scene_models_projected_vertices_[face.vertices[0]];
            Vertex v2 = scene_models_projected_vertices_[face.vertices[1]];
            Vertex v3 = scene_models_projected_vertices_[face.vertices[2]];
            
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

void EditModelScheme::HandleSelection(simd_float2 loc) {
    if (!input_enabled) {
        return;
    }
    
    std::pair<int, float> controls_selection = ControlModelClicked(loc);
    std::pair<int, float> model_selection = ModelClicked(loc);
    
    if (model_selection.first != -1 && controls_selection.first != -1) {
        if (model_selection.second > controls_selection.second) {
            if (controls_selection.first < 3) {
                selected_arrow = controls_selection.first;
                current_action = new ModelMoveAction(scene_, selected_model);
            }
        } else {
            selected_model = model_selection.first;
        }
    } else if (model_selection.first != -1 ) {
        selected_model = model_selection.first;
    } else if (controls_selection.first != -1) {
        if (controls_selection.first < 3) {
            selected_arrow = controls_selection.first;
            current_action = new ModelMoveAction(scene_, selected_model);
            current_action->BeginRecording();
        }
    } else {
        selected_model = -1;
        selected_arrow = -1;
    }
}

void EditModelScheme::SetControlsOrigin() {
    if (selected_model != -1) {
        controls_origin_ = scene_->GetModelUniforms(selected_model)->position;
    } else {
        simd_float3 behind_camera;
        behind_camera.x = camera_->pos.x - camera_->vector.x*10;
        behind_camera.y = camera_->pos.y - camera_->vector.y*10;
        behind_camera.z = camera_->pos.z - camera_->vector.z*10;
        controls_origin_ = behind_camera;
    }
}

void EditModelScheme::SetArrowProjections() {
    arrow_projections[0].x = control_models_projected_vertices_[0].x;
    arrow_projections[0].y = control_models_projected_vertices_[0].y;
    arrow_projections[1].x = control_models_projected_vertices_[12].x;
    arrow_projections[1].y = control_models_projected_vertices_[12].y;
    
    arrow_projections[2].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE].x;
    arrow_projections[2].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE].y;
    arrow_projections[3].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE+12].x;
    arrow_projections[3].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE+12].y;
    
    arrow_projections[4].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE*2].x;
    arrow_projections[4].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE*2].y;
    arrow_projections[5].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE*2+12].x;
    arrow_projections[5].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE*2+12].y;
}

void EditModelScheme::HandleMouseMovement(float x, float y, float dx, float dy) {
    Scheme::HandleMouseMovement(x, y, dx, dy);
    
    if (input_enabled) {
        if (selected_arrow != -1) {
            // find the projected location of the tip and the base
            simd_float2 base = arrow_projections[selected_arrow*2];
            simd_float2 tip = arrow_projections[selected_arrow*2+1];
            
            // find direction to move
            float xDiff = tip.x-base.x;
            float yDiff = tip.y-base.y;
            
            float mag = sqrt(pow(xDiff, 2) + pow(yDiff, 2));
            xDiff /= mag;
            yDiff /= mag;
            
            float mvmt = xDiff * dx + yDiff * (-dy);
            
            // move
            ModelUniforms arrow_uniform = controls_model_uniforms_[selected_arrow];
            float x_vec = 0;
            float y_vec = 0;
            float z_vec = 1;
            // gimbal locked
            
            // around z axis
            //x_vec = x_vec*cos(arrow_uniform.angle.z)-y_vec*sin(arrow_uniform.angle.z);
            //y_vec = x_vec*sin(arrow_uniform.angle.z)+y_vec*cos(arrow_uniform.angle.z);
            
            // around y axis
            float newx = x_vec*cos(arrow_uniform.angle.y)+z_vec*sin(arrow_uniform.angle.y);
            z_vec = -x_vec*sin(arrow_uniform.angle.y)+z_vec*cos(arrow_uniform.angle.y);
            x_vec = newx;
            
            // around x axis
            float newy = y_vec*cos(arrow_uniform.angle.x)-z_vec*sin(arrow_uniform.angle.x);
            z_vec = y_vec*sin(arrow_uniform.angle.x)+z_vec*cos(arrow_uniform.angle.x);
            y_vec = newy;
            
            x_vec *= 0.01*mvmt;
            y_vec *= 0.01*mvmt;
            z_vec *= 0.01*mvmt;
            
            if (selected_model != -1) {
                ModelUniforms *mu = scene_->GetModelUniforms(selected_model);
                
                mu->position.x += x_vec;
                mu->position.y += y_vec;
                mu->position.z += z_vec;
                
                mu->rotate_origin.x += x_vec;
                mu->rotate_origin.y += y_vec;
                mu->rotate_origin.z += z_vec;
                
                should_reset_static_buffers = true;
            }
        }
    }
}

void EditModelScheme::SaveSelectedModelToFile(std::string path) {
    if (selected_model == -1) {
        return;
    }
    
    scene_->GetModel(selected_model)->SaveToFile(path);
}

void EditModelScheme::ModelEditMenu() {
    ImGui::Text("Selected Model ID: %i", selected_model - 3);
    
    ImGui::SetCursorPos(ImVec2(30, 30));
    ImGui::Text("Location: ");
    
    ImGui::SetCursorPos(ImVec2(50, 50));
    ImGui::Text("x: ");
    ImGui::SetCursorPos(ImVec2(70, 50));
    std::string x_input = TextField(std::to_string(scene_->GetModelUniforms(selected_model)->position.x), "##modelx");
    if (isFloat(x_input)) {
        float new_x = std::stof(x_input);
        scene_->GetModelUniforms(selected_model)->position.x = new_x;
        scene_->GetModelUniforms(selected_model)->rotate_origin.x = new_x;
    }
    
    ImGui::SetCursorPos(ImVec2(50, 80));
    ImGui::Text("y: ");
    ImGui::SetCursorPos(ImVec2(70, 80));
    std::string y_input = TextField(std::to_string(scene_->GetModelUniforms(selected_model)->position.y), "##modely");
    if (isFloat(y_input)) {
        float new_y = std::stof(y_input);
        scene_->GetModelUniforms(selected_model)->position.y = new_y;
        scene_->GetModelUniforms(selected_model)->rotate_origin.y = new_y;
    }
    
    ImGui::SetCursorPos(ImVec2(50, 110));
    ImGui::Text("z: ");
    ImGui::SetCursorPos(ImVec2(70, 110));
    std::string z_input = TextField(std::to_string(scene_->GetModelUniforms(selected_model)->position.z), "##modelz");
    if (isFloat(z_input)) {
        float new_z = std::stof(z_input);
        scene_->GetModelUniforms(selected_model)->position.z = new_z;
        scene_->GetModelUniforms(selected_model)->rotate_origin.z = new_z;
    }
    
    ImGui::SetCursorPos(ImVec2(50, 140));
    ImGui::Text("Number of Animations: %u", scene_->GetModel(selected_model)->NumAnimations());
    
    ImGui::SetCursorPos(ImVec2(70, 170));
    ImGui::Text("play: ");
    ImGui::SetCursorPos(ImVec2(110, 170));
    std::string aid = TextField(std::to_string(wanted_aid), "##aid");
    if (isUnsignedLong(aid)) {
        wanted_aid = std::stoul(aid);
        
    }
    ImGui::SetCursorPos(ImVec2(70, 200));
    if (ImGui::Button("Play", ImVec2(100,30))) {
        scene_->GetModel(selected_model)->StartAnimation(wanted_aid);
    }
    
    ImGui::SetCursorPos(ImVec2(70, 250));
    if (ImGui::Button("New Animation", ImVec2(100,30))) {
        scene_->GetModel(selected_model)->MakeAnimation();
    }
}

void EditModelScheme::RightMenu() {
    ImGui::SetNextWindowPos(ImVec2(window_width_ - right_menu_width_, UI_start_.y));
    ImGui::SetNextWindowSize(ImVec2(right_menu_width_, window_height_ - UI_start_.y));
    ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.0f, 0.0f, 0.0f, 255.0f));
    ImGui::Begin("side", &show_UI, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoResize);
    
    ImGui::SetCursorPos(ImVec2(20, 10));
    if (selected_model != -1) {
        ModelEditMenu();
    } else {
        ImGui::Text("Nothing Selected");
    }
    
    ImGui::PopStyleColor();
    
    ImGui::End();
}

void EditModelScheme::MainWindow() {
    ImGui::SetNextWindowPos(ImVec2(UI_start_.x, UI_start_.y));
    ImGui::SetNextWindowSize(ImVec2(window_width_ - right_menu_width_, window_height_));
    ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.0f, 0.0f, 0.0f, 0.0f));
    ImGui::Begin("main", &show_UI, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoResize);
    
    // Display FPS
    ImGui::SetCursorPos(ImVec2(5, 10));
    ImGui::Text("%.1f FPS", ImGui::GetIO().Framerate);
    ImGui::PopStyleColor();
    
    ImGui::End();
}

void EditModelScheme::BuildUI() {
    MainWindow();
    
    RightMenu();
}

void EditModelScheme::SetBufferContents(Vertex *smv, Vertex *smpv, Face *smf, Node *smn, Vertex *smpn, Vertex *cmv, Vertex *cmpv, Face *cmf) {
    Scheme::SetBufferContents(smv, smpv, smf, smn, smpn, cmv, cmpv, cmf);
    SetArrowProjections();
}

void EditModelScheme::Update() {
    Scheme::Update();
    
    for (std::size_t mid = 0; mid < scene_->NumModels(); mid++) {
        scene_->GetModel(mid)->UpdateAnimation(1 / fps);
    }
}
