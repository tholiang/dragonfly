//
//  EditFEVScheme.mm
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#import <Foundation/Foundation.h>
#include "EditFEVScheme.h"

using namespace DragonflyUtils;


EditFEVScheme::EditFEVScheme() {
    type = SchemeType::EditFEV;
    
    selected_edge = simd_make_int2(-1, -1);
    
    should_render.faces = true;
    should_render.edges = true;
    should_render.vertices = true;
    should_render.nodes = false;
    
    CreateControlsModels();
}

EditFEVScheme::~EditFEVScheme() {
    
}

void EditFEVScheme::CreateControlsModels() {
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

int EditFEVScheme::GetVertexModel(int vid) {
    if (vid == -1) {
        return -1;
    }
    
    int mid = 0;
    
    for (int i = 1; i < scene_->GetModels()->size(); i++) {
        if (vid < scene_->GetModel(i)->VertexStart()) {
            return mid;
        }
        mid++;
    }
    
    return mid;
}

void EditFEVScheme::HandleMouseDown(simd_float2 loc, bool left) {
    Scheme::HandleMouseDown(loc, left);
    
    loc.x = ((float) loc.x / (float) window_width_)*2 - 1;
    loc.y = -(((float) loc.y / (float) window_height_)*2 - 1);
    
    if (!left) {
        if (selected_face != -1 || selected_edge.x != -1) {
            rightclick_popup_loc_ = loc;
            rightclick_popup_size_ = simd_make_float2(90/(float)(window_width_/2), 20/(float)(window_height_/2));
            render_rightclick_popup_ = true;
        } else {
            render_rightclick_popup_ = false;
        }
    }
}

void EditFEVScheme::HandleMouseUp(simd_float2 loc, bool left) {
    Scheme::HandleMouseUp(loc, left);
    
    loc.x = ((float) loc.x / (float) window_width_)*2 - 1;
    loc.y = -(((float) loc.y / (float) window_height_)*2 - 1);
    
    if (left) {
        selected_arrow = -1;
        
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

std::pair<std::pair<int, int>, float> EditFEVScheme::FaceClicked(simd_float2 loc) {
    float d1, d2, d3;
    bool has_neg, has_pos;
    
    float minZ = -1;
    int clickedFid = -1;
    int clickedMid = -1;
    
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
                    clickedFid = fid;
                    clickedMid = mid;
                }
            }
        }
    }
    
    return std::make_pair(std::make_pair(clickedFid, clickedMid), minZ);
}

std::pair<std::pair<int, int>, float> EditFEVScheme::VertexClicked(simd_float2 loc) {
    float minZ = -1;
    int clickedVid = -1;
    int clickedMid = -1;
    
    int vid = 0;
    for (int mid = 0; mid < scene_->NumModels(); mid++) {
        Model *m = scene_->GetModel(mid);
        int vid_end = vid + m->NumVertices();
        
        for (; vid < vid_end; vid++) {
            Vertex vertex = scene_models_projected_vertices_[vid];
            float x_min = vertex.x-0.007;
            float x_max = vertex.x+0.007;
            float y_min = vertex.y-0.007 * aspect_ratio_;
            float y_max = vertex.y+0.007 * aspect_ratio_;
            
            if (loc.x <= x_max && loc.x >= x_min && loc.y <= y_max && loc.y >= y_min) {
                if (minZ == -1 || vertex.z < minZ) {
                    minZ = vertex.z-0.001;
                    clickedVid = vid;
                    clickedMid = mid;
                }
            }
        }
    }
    
    return std::make_pair(std::make_pair(clickedVid, clickedMid), minZ);
}

std::pair<std::pair<std::pair<int, int>, int>, float> EditFEVScheme::EdgeClicked(simd_float2 loc) {
    float d1, d2, d3;
    bool has_neg, has_pos;
    
    float minZ = -1;
    int clickedv1 = -1;
    int clickedv2 = -1;
    int clickedMid = -1;
    
    int fid = 0;
    for (int mid = 0; mid < scene_->NumModels(); mid++) {
        Model *m = scene_->GetModel(mid);
        int fid_end = fid + m->NumFaces();
        
        for (; fid < fid_end; fid++) {
            Face face = scene_models_faces_[fid];
            
            for (int vid = 0; vid < 3; vid++) {
                Vertex v1 = scene_models_projected_vertices_[face.vertices[vid]];
                Vertex v2 = scene_models_projected_vertices_[face.vertices[(vid+1) % 3]];
                
                vector_float2 edgeVec = simd_make_float2(v1.x-v2.x, v1.y-v2.y);
                float mag = sqrt(pow(edgeVec.x, 2) + pow(edgeVec.y, 2));
                if (mag == 0) {
                    continue;
                }
                edgeVec.x /= mag;
                edgeVec.y /= mag;
                
                edgeVec.x *= 0.01;
                edgeVec.y *= 0.01;
                
                Vertex v1plus = simd_make_float3(v1.x+edgeVec.y, v1.y-edgeVec.x, v1.z);
                Vertex v1sub = simd_make_float3(v1.x-edgeVec.y, v1.y+edgeVec.x, v1.z);
                Vertex v2plus = simd_make_float3(v2.x+edgeVec.y, v2.y-edgeVec.x, v2.z);
                Vertex v2sub = simd_make_float3(v2.x-edgeVec.y, v2.y+edgeVec.x, v2.z);
                
                if (InTriangle(loc, v1plus, v1sub, v2plus) || InTriangle(loc, v1sub, v2sub, v2plus)) {
                    float dist1 = dist2to3(loc, v1);
                    float dist2 = dist2to3(loc, v2);
                    
                    float total_dist = dist1 + dist2;
                    float weightedZ = v1.z*(dist1/total_dist);
                    weightedZ += v2.z*(dist2/total_dist);
                    float z = weightedZ;
                    
                    if (minZ == -1 || z < minZ) {
                        minZ = z-0.0001;
                        clickedv1 = face.vertices[vid];
                        clickedv2 = face.vertices[(vid+1) % 3];
                        clickedMid = mid;
                    }
                }
            }
        }
    }
    
    return std::make_pair(std::make_pair(std::make_pair(clickedv1, clickedv2), clickedMid), minZ);
}

bool EditFEVScheme::ClickOnScene(simd_float2 loc) {
    if (render_rightclick_popup_ && InRectangle(rightclick_popup_loc_, rightclick_popup_size_, loc)) {
        return false;
    }
    
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

void EditFEVScheme::HandleSelection(simd_float2 loc) {
    std::pair<int, float> controls_selection = ControlModelClicked(loc);
    std::pair<std::pair<int, int>, float> face_selection = FaceClicked(loc);
    std::pair<std::pair<std::pair<int, int>, int>, float> edge_selection = EdgeClicked(loc);
    std::pair<std::pair<int, int>, float> vertex_selection = VertexClicked(loc);
    
    float minZ = -1;
    
    bool nothing_clicked = true;
    
    if (controls_selection.first != -1) {
        if (controls_selection.first < 3) {
            selected_arrow = controls_selection.first;
            minZ = controls_selection.second;
            
            Model *m = scene_->GetModel(selected_model);
            
            if (selected_face != -1) {
                current_action = new FaceMoveAction(m, selected_face - m->FaceStart());
                current_action->BeginRecording();
            } else if (selected_edge.x != -1) {
                current_action = new EdgeMoveAction(m, selected_edge.x - m->VertexStart(), selected_edge.y - m->VertexStart());
                current_action->BeginRecording();
            } else if (selected_vertex != -1) {
                current_action = new VertexMoveAction(m, selected_vertex - m->VertexStart());
                current_action->BeginRecording();
            }
        }

        nothing_clicked = false;
    }
    
    if (face_selection.first.first != -1) {
        if (face_selection.second < minZ || minZ == -1) {
            selected_arrow = -1;
            selected_face = face_selection.first.first;
            selected_model = face_selection.first.second;
            minZ = face_selection.second;
            
            Face face = scene_models_faces_[selected_face];
            
            vertex_render_uniforms.selected_vertices[0] = face.vertices[0];
            vertex_render_uniforms.selected_vertices[1] = face.vertices[1];
            vertex_render_uniforms.selected_vertices[2] = face.vertices[2];
            
            nothing_clicked = false;
        }
    }
    
    if (edge_selection.first.first.first != -1) {
        if (edge_selection.second < minZ || minZ == -1) {
            selected_arrow = -1;
            selected_face = -1;
            selected_edge.x = edge_selection.first.first.first;
            selected_edge.y = edge_selection.first.first.second;
            selected_model = edge_selection.first.second;
            minZ = edge_selection.second;

            vertex_render_uniforms.selected_vertices[0] = selected_edge.x;
            vertex_render_uniforms.selected_vertices[1] = selected_edge.y;
            vertex_render_uniforms.selected_vertices[2] = -1;

            nothing_clicked = false;
        }
    }

    if (vertex_selection.first.first != -1) {
        if (vertex_selection.second < minZ || minZ == -1) {
            selected_arrow = -1;
            selected_face = -1;
            selected_edge.x = -1;
            selected_edge.y = -1;
            selected_vertex = vertex_selection.first.first;
            selected_model = vertex_selection.first.second;
            minZ = vertex_selection.second;

            vertex_render_uniforms.selected_vertices[0] = selected_vertex;
            vertex_render_uniforms.selected_vertices[1] = -1;
            vertex_render_uniforms.selected_vertices[2] = -1;

            nothing_clicked = false;
        }
    }
    
    if (nothing_clicked) {
        selected_arrow = -1;
        selected_model = -1;
        selected_face = -1;
        selected_edge = -1;
        selected_vertex = -1;
        
        vertex_render_uniforms.selected_vertices[0] = -1;
        vertex_render_uniforms.selected_vertices[1] = -1;
        vertex_render_uniforms.selected_vertices[2] = -1;
    }
}

void EditFEVScheme::SetControlsOrigin() {
    if (selected_face != -1) {
        Face face = scene_models_faces_[selected_face];
        controls_origin_ = TriAvg(scene_models_vertices_[face.vertices[0]], scene_models_vertices_[face.vertices[1]], scene_models_vertices_[face.vertices[2]]);
    } else if (selected_edge.x != -1) {
        controls_origin_ = BiAvg(scene_models_vertices_[selected_edge.x], scene_models_vertices_[selected_edge.y]);
    } else if (selected_vertex != -1) {
        controls_origin_ = scene_models_vertices_[selected_vertex];
    } else {
        simd_float3 behind_camera;
        behind_camera.x = camera_->pos.x - camera_->vector.x*10;
        behind_camera.y = camera_->pos.y - camera_->vector.y*10;
        behind_camera.z = camera_->pos.z - camera_->vector.z*10;
        controls_origin_ = behind_camera;
    }
}

void EditFEVScheme::SetArrowProjections() {
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

void EditFEVScheme::HandleMouseMovement(float x, float y, float dx, float dy) {
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
            
            if (selected_face != -1) {
                Model *model = scene_->GetModel(selected_model);
                unsigned long modelFaceID = selected_face - model->FaceStart();
                Face *selected = model->GetFace(modelFaceID);
                
                model->MoveVertexBy(selected->vertices[0], x_vec, y_vec, z_vec);
                model->MoveVertexBy(selected->vertices[1], x_vec, y_vec, z_vec);
                model->MoveVertexBy(selected->vertices[2], x_vec, y_vec, z_vec);
                
                should_reset_static_buffers = true;
            } else if (selected_vertex != -1) {
                Model *model = scene_->GetModel(selected_model);
                unsigned long modelVertexID = selected_vertex - model->VertexStart();
                model->MoveVertexBy(modelVertexID, x_vec, y_vec, z_vec);
                
                should_reset_static_buffers = true;
            } else if (selected_edge.x != -1) {
                Model *model = scene_->GetModel(selected_model);
                unsigned long modelVertex1ID = selected_edge.x - model->VertexStart();
                unsigned long modelVertex2ID = selected_edge.y - model->VertexStart();
                model->MoveVertexBy(modelVertex1ID, x_vec, y_vec, z_vec);
                model->MoveVertexBy(modelVertex2ID, x_vec, y_vec, z_vec);
                
                should_reset_static_buffers = true;
            }
        }
    }
}

void EditFEVScheme::AddVertexToFace (int fid, int mid) {
    Model *model = scene_->GetModels()->at(mid);
    unsigned long modelFaceID = fid - model->FaceStart();
    
    Face *selected = model->GetFace(modelFaceID);
    int vid1 = selected->vertices[0];
    int vid2 = selected->vertices[1];
    int vid3 = selected->vertices[2];
    Vertex v1 = scene_models_vertices_[vid1 + model->VertexStart()];
    Vertex v2 = scene_models_vertices_[vid2 + model->VertexStart()];
    Vertex v3 = scene_models_vertices_[vid3 + model->VertexStart()];
    
    ModelUniforms *mu = scene_->GetModelUniforms(selected_model);
    v1.x -= mu->position.x;
    v1.y -= mu->position.y;
    v1.z -= mu->position.z;
    v2.x -= mu->position.x;
    v2.y -= mu->position.y;
    v2.z -= mu->position.z;
    v3.x -= mu->position.x;
    v3.y -= mu->position.y;
    v3.z -= mu->position.z;
    
    Vertex new_v = TriAvg(v1, v2, v3);
    unsigned new_vid = model->MakeVertex(new_v.x, new_v.y, new_v.z);
    
    //1,2,new
    selected->vertices[2] = new_vid;
    
    //2,3,new
    model->MakeFace(vid2, vid3, new_vid, selected->color);
    
    //1,3,new
    model->MakeFace(vid1, vid3, new_vid, selected->color);
    
    scene_vertex_length_++;
    scene_face_length_+=2;
    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

void EditFEVScheme::AddVertexToEdge (int vid1, int vid2, int mid) {
    Model *model = scene_->GetModels()->at(mid);
    
    int model_vid1 = vid1 - model->VertexStart();
    int model_vid2 = vid2 - model->VertexStart();
    
    std::vector<unsigned long> fids = model->GetEdgeFaces(model_vid1, model_vid2);
    
    ModelUniforms *mu = scene_->GetModelUniforms(selected_model);
    
    Vertex v1 = scene_models_vertices_[vid1];
    Vertex v2 = scene_models_vertices_[vid2];
    v1.x -= mu->position.x;
    v1.y -= mu->position.y;
    v1.z -= mu->position.z;
    v2.x -= mu->position.x;
    v2.y -= mu->position.y;
    v2.z -= mu->position.z;
    Vertex new_v = BiAvg(v1, v2);
    unsigned new_vid = model->MakeVertex(new_v.x, new_v.y, new_v.z);
    
    for (std::size_t i = 0; i < fids.size(); i++) {
        unsigned long fid = fids[i];
        Face *f = model->GetFace(fid);
        unsigned long fvid1 = f->vertices[0];
        unsigned long fvid2 = f->vertices[1];
        unsigned long fvid3 = f->vertices[2];
        
        long long other_vid = -1;
        
        if (model_vid1 == fvid1) {
            if (model_vid2 == fvid2) {
                other_vid = fvid3;
            } else if (model_vid2 == fvid3) {
                other_vid = fvid2;
            }
        } else if (model_vid1 == fvid2) {
            if (model_vid2 == fvid1) {
                other_vid = fvid3;
            } else if (model_vid2 == fvid3) {
                other_vid = fvid1;
            }
        } else if (model_vid1 == fvid3) {
            if (model_vid2 == fvid1) {
                other_vid = fvid2;
            } else if (model_vid2 == fvid2) {
                other_vid = fvid1;
            }
        }
        
        if (other_vid != -1) {
            f->vertices[0] = model_vid1;
            f->vertices[1] = new_vid;
            f->vertices[2] = other_vid;
            
            model->MakeFace(model_vid2, new_vid, other_vid, f->color);
            scene_face_length_++;
        }
    }
    
    scene_vertex_length_++;
    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

void EditFEVScheme::RightClickPopup() {
    ImVec2 pixel_loc = ImVec2(window_width_ * (rightclick_popup_loc_.x+1)/2 - UI_start_.x, window_height_ * (2-(rightclick_popup_loc_.y+1))/2 - UI_start_.y);
    ImGui::SetCursorPos(pixel_loc);
    
    ImVec2 button_size = ImVec2(window_width_ * rightclick_popup_size_.x/2, window_height_ * rightclick_popup_size_.y/2);
    
    if (selected_face != -1 || selected_edge.x != -1) {
        if (ImGui::Button("Add Vertex", ImVec2(button_size.x, button_size.y))) {
            render_rightclick_popup_ = false;
            if (selected_face != -1) {
                Model* m = scene_->GetModel(selected_model);
                current_action = new FaceAddVertexAction(m, m->NumVertices(), selected_face - m->FaceStart());
                
                current_action->BeginRecording();
                
                AddVertexToFace(selected_face, selected_model);
                current_action->EndRecording();
                
                past_actions.push_front(current_action);
                
                current_action = NULL;
            } else if (selected_edge.x != -1) {
                Model* m = scene_->GetModel(selected_model);
                current_action = new EdgeAddVertexAction(m, m->NumVertices(), selected_edge.x - m->VertexStart(), selected_edge.y - m->VertexStart());
                
                current_action->BeginRecording();
                AddVertexToEdge(selected_edge.x, selected_edge.y, selected_model);
                current_action->EndRecording();
                
                past_actions.push_front(current_action);
                
                current_action = NULL;
            }
        }
    }
}

void EditFEVScheme::VertexEditMenu() {
    Model *model = scene_->GetModel(selected_model);
    
    ImGui::Text("Selected Model ID: %i", selected_model);
    ImGui::SetCursorPos(ImVec2(20, 30));
    ImGui::Text("Selected Vertex ID: %lu", selected_vertex - model->VertexStart());
    
    int current_y = 60;
    
    std::vector<unsigned long> linked_nodes = model->GetLinkedNodes(selected_vertex - model->VertexStart());
    for (int i = 0; i < linked_nodes.size(); i++) {
        ImGui::SetCursorPos(ImVec2(30, current_y));
        ImGui::Text("Linked to node %lu", linked_nodes[i]);
        
        if (linked_nodes.size() > 1) {
        ImGui::SetCursorPos(ImVec2(150, current_y));
            if (ImGui::Button("Unlink")) {
                model->UnlinkNodeAndVertex(selected_vertex - model->VertexStart(), linked_nodes[i]);
                should_reset_static_buffers = true;
            }
        }
        
        current_y += 30;
    }
    
    ImGui::SetCursorPos(ImVec2(30, current_y));
    ImGui::Text("Link to node: ");
    char buf [128] = "";
    ImGui::SetCursorPos(ImVec2(130, current_y));
    if (ImGui::InputText("##linknode", buf, IM_ARRAYSIZE(buf), ImGuiInputTextFlags_EnterReturnsTrue)) {
        if (isUnsignedLong(buf)) {
            unsigned long nid = std::stoul(buf);
            model->LinkNodeAndVertex(selected_vertex - model->VertexStart(), nid);
            should_reset_static_buffers = true;
        }
    }
    
}

void EditFEVScheme::EdgeEditMenu() {
    ImGui::Text("Selected Model ID: %i", selected_model - 3);
    ImGui::SetCursorPos(ImVec2(20, 30));
    ImGui::Text("Selected Edge Vertex IDs: %lu %lu", selected_edge.x - scene_->GetModel(selected_model)->VertexStart(), selected_edge.y - scene_->GetModel(selected_model)->VertexStart());
}

void EditFEVScheme::FaceEditMenu() {
    ImGui::Text("Selected Model ID: %i", selected_model - 3);
    ImGui::SetCursorPos(ImVec2(20, 30));
    ImGui::Text("Selected Face ID: %lu", selected_face - scene_->GetModel(selected_model)->FaceStart());
}

void EditFEVScheme::RightMenu() {
    ImGui::SetNextWindowPos(ImVec2(window_width_ - right_menu_width_, UI_start_.y));
    ImGui::SetNextWindowSize(ImVec2(right_menu_width_, window_height_ - UI_start_.y));
    ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.0f, 0.0f, 0.0f, 255.0f));
    ImGui::Begin("side", &show_UI, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoResize);
    
    ImGui::SetCursorPos(ImVec2(20, 10));
    if (selected_vertex != -1) {
        VertexEditMenu();
    } else if (selected_edge.x != -1) {
        EdgeEditMenu();
    } else if (selected_face != -1) {
        FaceEditMenu();
    } else {
        ImGui::Text("Nothing Selected");
    }
    
    ImGui::PopStyleColor();
    
    ImGui::End();
}

void EditFEVScheme::MainWindow() {
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

void EditFEVScheme::BuildUI() {
    MainWindow();
    
    RightMenu();
}

void EditFEVScheme::SetBufferContents(Vertex *smv, Vertex *smpv, Face *smf, Node *smn, Vertex *smpn, Vertex *cmv, Vertex *cmpv, Face *cmf) {
    Scheme::SetBufferContents(smv, smpv, smf, smn, smpn, cmv, cmpv, cmf);
    SetArrowProjections();
}
