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
    
    button_size_ = ImVec2(100, 30);
    
    should_render.faces = true;
    should_render.edges = false;
    should_render.vertices = false;
    should_render.nodes = false;
    should_render.slices = false;
    
    CreateControlsModels();
}

EditModelScheme::~EditModelScheme() {
    
}

void EditModelScheme::CreateControlsModels() {
    z_arrow = new Arrow(0);
    
    ModelUniforms z_arrow_uniform;
    z_arrow_uniform.b.pos = simd_make_float3(0, 0, 0);
    z_arrow_uniform.rotate_origin = simd_make_float3(0, 0, 0);
    
    controls_model_uniforms_.push_back(z_arrow_uniform);
    controls_model_default_bases_.push_back(z_arrow_uniform.b);
    arrow_projections[0] = simd_make_float2(0,0);
    arrow_projections[1] = simd_make_float2(0,1);
    
    controls_models_.push_back(z_arrow);
    
    x_arrow = new Arrow(1, simd_make_float4(0, 1, 0, 1));
    
    ModelUniforms x_arrow_uniform;
    x_arrow_uniform.b.pos = simd_make_float3(0, 0, 0);
    x_arrow_uniform.rotate_origin = simd_make_float3(0, 0, 0);
    //x_arrow_uniform.angle = simd_make_float3(M_PI_2, 0, 0);
    RotateBasisOnY(&x_arrow_uniform.b, M_PI_2);
    
    controls_model_uniforms_.push_back(x_arrow_uniform);
    controls_model_default_bases_.push_back(x_arrow_uniform.b);
    arrow_projections[2] = simd_make_float2(0,0);
    arrow_projections[3] = simd_make_float2(0,0);
    
    controls_models_.push_back(x_arrow);
    
    y_arrow = new Arrow(2, simd_make_float4(0, 0, 1, 1));
    
    ModelUniforms y_arrow_uniform;
    y_arrow_uniform.b.pos = simd_make_float3(0, 0, 0);
    y_arrow_uniform.rotate_origin = simd_make_float3(0, 0, 0);
//    y_arrow_uniform.angle = simd_make_float3(0, -M_PI_2, 0);
    RotateBasisOnX(&y_arrow_uniform.b, M_PI_2);
    
    controls_model_uniforms_.push_back(y_arrow_uniform);
    controls_model_default_bases_.push_back(y_arrow_uniform.b);
    arrow_projections[4] = simd_make_float2(0,0);
    arrow_projections[5] = simd_make_float2(1,0);
    
    controls_models_.push_back(y_arrow);
    
    
    z_rotator = new Rotator(3);
    z_rotator->ScaleBy(1, 1, 0.8);
    
    ModelUniforms z_rotator_uniform;
    z_rotator_uniform.b.pos = simd_make_float3(0, 0, 0);
    z_rotator_uniform.rotate_origin = simd_make_float3(0, 0, 0);
    RotateBasisOnZ(&z_rotator_uniform.b, M_PI_2);
    
    controls_model_uniforms_.push_back(z_rotator_uniform);
    controls_model_default_bases_.push_back(z_rotator_uniform.b);
    rotator_projections[0] = simd_make_float2(0,0);
    rotator_projections[1] = simd_make_float2(0,1);
    
    controls_models_.push_back(z_rotator);
    
    x_rotator = new Rotator(4, simd_make_float4(0, 1, 0, 1));
    x_rotator->ScaleBy(1, 1, 0.8);
    
    ModelUniforms x_rotator_uniform;
    x_rotator_uniform.b.pos = simd_make_float3(0, 0, 0);
    x_rotator_uniform.rotate_origin = simd_make_float3(0, 0, 0);
    //x_arrow_uniform.angle = simd_make_float3(M_PI_2, 0, 0);
    RotateBasisOnY(&x_rotator_uniform.b, M_PI_2);
    
    controls_model_uniforms_.push_back(x_rotator_uniform);
    controls_model_default_bases_.push_back(x_rotator_uniform.b);
    rotator_projections[2] = simd_make_float2(0,0);
    rotator_projections[3] = simd_make_float2(0,0);
    
    controls_models_.push_back(x_rotator);
    
    y_rotator = new Rotator(5, simd_make_float4(0, 0, 1, 1));
    y_rotator->ScaleBy(1, 1, 0.8);
    
    ModelUniforms y_rotator_uniform;
    y_rotator_uniform.b.pos = simd_make_float3(0, 0, 0);
    y_rotator_uniform.rotate_origin = simd_make_float3(0, 0, 0);
//    y_arrow_uniform.angle = simd_make_float3(0, -M_PI_2, 0);
    RotateBasisOnX(&y_rotator_uniform.b, M_PI_2);
    
    controls_model_uniforms_.push_back(y_rotator_uniform);
    controls_model_default_bases_.push_back(y_rotator_uniform.b);
    rotator_projections[4] = simd_make_float2(0,0);
    rotator_projections[5] = simd_make_float2(1,0);
    
    controls_models_.push_back(y_rotator);
}

void EditModelScheme::HandleMouseDown(simd_float2 loc, bool left) {
    Scheme::HandleMouseDown(loc, left);
    
    loc.x = ((float) loc.x / (float) window_width_)*2 - 1;
    loc.y = -(((float) loc.y / (float) window_height_)*2 - 1);
    
    if (!left) {
        if (selected_model > -1) {
            rightclick_popup_loc_ = loc;
            render_rightclick_popup_ = true;
        } else {
            render_rightclick_popup_ = false;
        }
    }
}

void EditModelScheme::HandleMouseUp(simd_float2 loc, bool left) {
    Scheme::HandleMouseUp(loc, left);
    
    loc.x = ((float) loc.x / (float) window_width_)*2 - 1;
    loc.y = -(((float) loc.y / (float) window_height_)*2 - 1);
    
    if (left) {
        selected_arrow = -1;
        selected_rotator = -1;
        
        if (!(render_rightclick_popup_ && InRectangle(rightclick_popup_loc_, rightclick_popup_size_, loc))) {
            render_rightclick_popup_ = false;
        }
    }
    
    if (current_action != NULL) {
        current_action->EndRecording();
        past_actions.push_back(current_action);
        current_action = NULL;
    }
}

bool EditModelScheme::ClickOnScene(simd_float2 loc) {
    if (render_rightclick_popup_ && InRectangle(rightclick_popup_loc_, rightclick_popup_size_, loc)) {
        return false;
    }
    
    int pixelX = window_width_ * (loc.x+1)/2;
    int pixelY = window_height_ * (loc.y+1)/2;
    
    if (pixelX < UI_start_.x || pixelX > UI_start_.x + window_width_ - right_menu_width_) {
        return false;
    }
    
    if (pixelY < 0 || pixelY > window_height_ - UI_start_.y) {
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
        } else if (controls_selection.first < 6) {
            selected_rotator = controls_selection.first - 3;
        }
    } else {
        selected_model = -1;
        selected_arrow = -1;
        selected_rotator = -1;
    }
}

void EditModelScheme::SetControlsBasis() {
    if (selected_model != -1) {
        controls_basis_ = scene_->GetModelUniforms(selected_model)->b;
    } else {
        simd_float3 behind_camera;
        behind_camera.x = camera_->pos.x - camera_->vector.x*10;
        behind_camera.y = camera_->pos.y - camera_->vector.y*10;
        behind_camera.z = camera_->pos.z - camera_->vector.z*10;
        controls_basis_.pos = behind_camera;
    }
}

void EditModelScheme::SetArrowProjections() {
    arrow_projections[0].x = control_models_projected_vertices_[4].x;
    arrow_projections[0].y = control_models_projected_vertices_[4].y;
    arrow_projections[1].x = control_models_projected_vertices_[9].x;
    arrow_projections[1].y = control_models_projected_vertices_[9].y;
    
    arrow_projections[2].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE+4].x;
    arrow_projections[2].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE+4].y;
    arrow_projections[3].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE+9].x;
    arrow_projections[3].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE+9].y;
    
    arrow_projections[4].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE*2+4].x;
    arrow_projections[4].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE*2+4].y;
    arrow_projections[5].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE*2+9].x;
    arrow_projections[5].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE*2+9].y;
    
    
    rotator_projections[0].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE*3+6].x;
    rotator_projections[0].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE*3+6].y;
    rotator_projections[1].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE*3+9].x;
    rotator_projections[1].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE*3+9].y;
    
    rotator_projections[2].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE*3+ROTATOR_VERTEX_SIZE+6].x;
    rotator_projections[2].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE*3+ROTATOR_VERTEX_SIZE+6].y;
    rotator_projections[3].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE*3+ROTATOR_VERTEX_SIZE+9].x;
    rotator_projections[3].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE*3+ROTATOR_VERTEX_SIZE+9].y;
    
    rotator_projections[4].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE*3+ROTATOR_VERTEX_SIZE*2+6].x;
    rotator_projections[4].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE*3+ROTATOR_VERTEX_SIZE*2+6].y;
    rotator_projections[5].x = control_models_projected_vertices_[ARROW_VERTEX_SIZE*3+ROTATOR_VERTEX_SIZE*2+9].x;
    rotator_projections[5].y = control_models_projected_vertices_[ARROW_VERTEX_SIZE*3+ROTATOR_VERTEX_SIZE*2+9].y;
}

void EditModelScheme::HandleMouseMovement(float x, float y, float dx, float dy) {
    Scheme::HandleMouseMovement(x, y, dx, dy);
    
    if (input_enabled) {
        if (selected_arrow != -1) {
            // find the projected location of the tip and the base
            simd_float2 top = arrow_projections[selected_arrow*2];
            simd_float2 bot = arrow_projections[selected_arrow*2+1];
            
            // find direction to move
            float xDiff = top.x-bot.x;
            float yDiff = top.y-bot.y;
            
            float mag = sqrt(pow(xDiff, 2) + pow(yDiff, 2));
            xDiff /= mag;
            yDiff /= mag;
            
            float mvmt = xDiff * dx + yDiff * (-dy);
            
            // move
            ModelUniforms arrow_uniform = controls_model_uniforms_[selected_arrow];
            float x_vec = arrow_uniform.b.z.x; // 0;
            float y_vec = arrow_uniform.b.z.y;// 0;
            float z_vec = arrow_uniform.b.z.z;// 1;
//            // gimbal locked
//
//            // around z axis
//            //x_vec = x_vec*cos(arrow_uniform.angle.z)-y_vec*sin(arrow_uniform.angle.z);
//            //y_vec = x_vec*sin(arrow_uniform.angle.z)+y_vec*cos(arrow_uniform.angle.z);
//
//            // around y axis
//            float newx = x_vec*cos(arrow_uniform.angle.y)+z_vec*sin(arrow_uniform.angle.y);
//            z_vec = -x_vec*sin(arrow_uniform.angle.y)+z_vec*cos(arrow_uniform.angle.y);
//            x_vec = newx;
//
//            // around x axis
//            float newy = y_vec*cos(arrow_uniform.angle.x)-z_vec*sin(arrow_uniform.angle.x);
//            z_vec = y_vec*sin(arrow_uniform.angle.x)+z_vec*cos(arrow_uniform.angle.x);
//            y_vec = newy;
            
            x_vec *= 0.01*mvmt;
            y_vec *= 0.01*mvmt;
            z_vec *= 0.01*mvmt;
            
            if (selected_model != -1) {
                ModelUniforms *mu = scene_->GetModelUniforms(selected_model);
                
                mu->b.pos.x += x_vec;
                mu->b.pos.y += y_vec;
                mu->b.pos.z += z_vec;
                
                mu->rotate_origin.x += x_vec;
                mu->rotate_origin.y += y_vec;
                mu->rotate_origin.z += z_vec;
                
                //should_reset_static_buffers = true;
            }
        } else if (selected_rotator != -1) {
            // find the projected location of the tip and the base
            simd_float2 top = rotator_projections[selected_rotator*2];
            simd_float2 bot = rotator_projections[selected_rotator*2+1];
            
            // find direction to move
            float xDiff = top.x-bot.x;
            float yDiff = top.y-bot.y;
            
            float mag = sqrt(pow(xDiff, 2) + pow(yDiff, 2));
            xDiff /= mag;
            yDiff /= mag;
            
            float mvmt = xDiff * dx + yDiff * (-dy);
            
            ModelUniforms *mu = scene_->GetModelUniforms(selected_model);
            if (selected_rotator == 0) {
                RotateBasisOnY(&mu->b, -mvmt / 100);
            } else if (selected_rotator == 1) {
                RotateBasisOnZ(&mu->b, -mvmt / 100);
            } else {
                RotateBasisOnX(&mu->b, -mvmt / 100);
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

void EditModelScheme::RightClickPopup() {
    ImVec2 pixel_loc = ImVec2(window_width_ * (rightclick_popup_loc_.x+1)/2 - UI_start_.x, window_height_ * (2-(rightclick_popup_loc_.y+1))/2 - UI_start_.y);
    ImGui::SetCursorPos(pixel_loc);
    
    num_right_click_buttons_ = 0;
    
    if (selected_model != -1) {
        num_right_click_buttons_++;
        if (ImGui::Button("Generate Normals", ImVec2(button_size_.x, button_size_.y))) {
            render_rightclick_popup_ = false;
            DragonflyUtils::FindNormals(scene_->GetModel(selected_model));
            should_reset_static_buffers = true;
        }
        pixel_loc.y += button_size_.y;
        ImGui::SetCursorPos(ImVec2(pixel_loc.x, pixel_loc.y));
    }
    
    if (selected_model != -1) {
        num_right_click_buttons_++;
        if (ImGui::Button("Flip Normals", ImVec2(button_size_.x, button_size_.y))) {
            render_rightclick_popup_ = false;
            DragonflyUtils::ReverseNormals(scene_->GetModel(selected_model));
            should_reset_static_buffers = true;
        }
        pixel_loc.y += button_size_.y;
        ImGui::SetCursorPos(ImVec2(pixel_loc.x, pixel_loc.y));
    }
    
    rightclick_popup_size_ = simd_make_float2((button_size_.x)/(float)(window_width_/2), (button_size_.y * num_right_click_buttons_)/(float)(window_height_/2));
}


void EditModelScheme::ModelEditMenu() {
    ImGui::Text("Selected Model ID: %i", selected_model);
    
    ImGui::SetCursorPos(ImVec2(30, 30));
    ImGui::Text("Location: ");
    
    ImGui::SetCursorPos(ImVec2(50, 50));
    ImGui::Text("x: ");
    ImGui::SetCursorPos(ImVec2(70, 50));
    std::string x_input = TextField(std::to_string(scene_->GetModelUniforms(selected_model)->b.pos.x), "##modelx");
    if (isFloat(x_input)) {
        float new_x = std::stof(x_input);
        scene_->GetModelUniforms(selected_model)->b.pos.x = new_x;
        scene_->GetModelUniforms(selected_model)->rotate_origin.x = new_x;
    }
    
    ImGui::SetCursorPos(ImVec2(50, 80));
    ImGui::Text("y: ");
    ImGui::SetCursorPos(ImVec2(70, 80));
    std::string y_input = TextField(std::to_string(scene_->GetModelUniforms(selected_model)->b.pos.y), "##modely");
    if (isFloat(y_input)) {
        float new_y = std::stof(y_input);
        scene_->GetModelUniforms(selected_model)->b.pos.y = new_y;
        scene_->GetModelUniforms(selected_model)->rotate_origin.y = new_y;
    }
    
    ImGui::SetCursorPos(ImVec2(50, 110));
    ImGui::Text("z: ");
    ImGui::SetCursorPos(ImVec2(70, 110));
    std::string z_input = TextField(std::to_string(scene_->GetModelUniforms(selected_model)->b.pos.z), "##modelz");
    if (isFloat(z_input)) {
        float new_z = std::stof(z_input);
        scene_->GetModelUniforms(selected_model)->b.pos.z = new_z;
        scene_->GetModelUniforms(selected_model)->rotate_origin.z = new_z;
    }
    
    
    ImGui::SetCursorPos(ImVec2(30, 140));
    ImGui::Text("Rotate By");

    ImGui::SetCursorPos(ImVec2(50, 170));
    ImGui::Text("x: ");
    ImGui::SetCursorPos(ImVec2(70, 170));
    angle_input_x = TextField(angle_input_x, "##modelax");

    ImGui::SetCursorPos(ImVec2(50, 200));
    ImGui::Text("y: ");
    ImGui::SetCursorPos(ImVec2(70, 200));
    angle_input_y = TextField(angle_input_y, "##modelay");

    ImGui::SetCursorPos(ImVec2(50, 230));
    ImGui::Text("z: ");
    ImGui::SetCursorPos(ImVec2(70, 230));
    angle_input_z = TextField(angle_input_z, "##modelaz");
    
    ImGui::SetCursorPos(ImVec2(50, 250));
    if (ImGui::Button("Rotate", ImVec2(80,30))) {
        float new_x = 0;
        float new_y = 0;
        float new_z = 0;
        if (isFloat(angle_input_x)) {
            new_x = std::stof(angle_input_x);
        }
        if (isFloat(angle_input_y)) {
            new_y = std::stof(angle_input_y);
        }
        if (isFloat(angle_input_z)) {
            new_z = std::stof(angle_input_z);
        }
        
        scene_->RotateModelBy(selected_model, new_x * M_PI / 180, new_y * M_PI / 180, new_z * M_PI / 180);
        
        angle_input_x = "0";
        angle_input_y = "0";
        angle_input_z = "0";
    }
    
    ImGui::SetCursorPos(ImVec2(30, 280));
    ImGui::Text("Scale By");

    ImGui::SetCursorPos(ImVec2(50, 310));
    ImGui::Text("x: ");
    ImGui::SetCursorPos(ImVec2(70, 310));
    scale_input_x = TextField(scale_input_x, "##modelsx");

    ImGui::SetCursorPos(ImVec2(50, 340));
    ImGui::Text("y: ");
    ImGui::SetCursorPos(ImVec2(70, 340));
    scale_input_y = TextField(scale_input_y, "##modelsy");

    ImGui::SetCursorPos(ImVec2(50, 370));
    ImGui::Text("z: ");
    ImGui::SetCursorPos(ImVec2(70, 370));
    scale_input_z = TextField(scale_input_z, "##modelsz");
    
    ImGui::SetCursorPos(ImVec2(50, 390));
    if (ImGui::Button("Scale", ImVec2(80,30))) {
        float new_x = 1;
        float new_y = 1;
        float new_z = 1;
        if (isFloat(scale_input_x)) {
            new_x = std::stof(scale_input_x);
        }
        if (isFloat(scale_input_y)) {
            new_y = std::stof(scale_input_y);
        }
        if (isFloat(scale_input_z)) {
            new_z = std::stof(scale_input_z);
        }
        
        ModelUniforms *mu = scene_->GetModelUniforms(selected_model);
        mu->scale.x = new_x;
        mu->scale.y = new_y;
        mu->scale.z = new_z;
    }
    
    ImGui::SetCursorPos(ImVec2(150, 390));
    if (ImGui::Button("Set Default", ImVec2(120,30))) {
        ModelUniforms *mu = scene_->GetModelUniforms(selected_model);
        scene_->GetModel(selected_model)->ScaleBy(mu->scale.x, mu->scale.y, mu->scale.z);
        mu->scale.x = 1;
        mu->scale.y = 1;
        mu->scale.z = 1;
        
        scale_input_x = "1";
        scale_input_y = "1";
        scale_input_z = "1";
        
        should_reset_static_buffers = true;
    }
    
    ImGui::SetCursorPos(ImVec2(50, 420));
    ImGui::Text("Number of Animations: %u", scene_->GetModel(selected_model)->NumAnimations());
    
    ImGui::SetCursorPos(ImVec2(70, 450));
    ImGui::Text("play: ");
    ImGui::SetCursorPos(ImVec2(110, 450));
    std::string aid = TextField(std::to_string(wanted_aid), "##aid");
    if (isUnsignedLong(aid)) {
        wanted_aid = std::stoul(aid);
        
    }
    ImGui::SetCursorPos(ImVec2(70, 480));
    if (ImGui::Button("Play", ImVec2(100,30))) {
        scene_->GetModel(selected_model)->StartAnimation(wanted_aid);
    }
    
    ImGui::SetCursorPos(ImVec2(70, 510));
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
    
    if (render_rightclick_popup_) {
        RightClickPopup();
    }
    
    ImGui::End();
}

void EditModelScheme::BuildUI() {
    MainWindow();
    
    RightMenu();
}

void EditModelScheme::SetBufferContents(Vertex *smv, Vertex *smpv, Face *smf, Node *smn, Vertex *smpn, Vertex *cmv, Vertex *cmpv, Face *cmf, Vertex *ssp) {
    Scheme::SetBufferContents(smv, smpv, smf, smn, smpn, cmv, cmpv, cmf, ssp);
    SetArrowProjections();
}

void EditModelScheme::Update() {
    Scheme::Update();
    
    for (std::size_t mid = 0; mid < scene_->NumModels(); mid++) {
        scene_->GetModel(mid)->UpdateAnimation(1 / fps);
    }
}
