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
    button_size_ = ImVec2(100, 30);
    
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
    
    drag_size.x = 0;
    drag_size.y = 0;
    
    if (!left) {
        if (vertex_render_uniforms.selected_vertices.size() > 0) {
            rightclick_popup_loc_ = loc;
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
        
        if (dist2to3(drag_size, simd_make_float3(0, 0, 0)) > 0.05) {
            SelectVerticesInDrag();
        }
    }
    
    drag_size.x = 0;
    drag_size.y = 0;
    
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
            
            if (!vertex_render_uniforms.selected_vertices.empty()) {
                std::vector<int> model_vertices;
                for (int i = 0; i < vertex_render_uniforms.selected_vertices.size(); i++) {
                    model_vertices.push_back(vertex_render_uniforms.selected_vertices[i] - m->VertexStart());
                }
                
                current_action = new VertexMoveAction(m, model_vertices);
                current_action->BeginRecording();
            }
        }

        nothing_clicked = false;
    }
    
    if (face_selection.first.first != -1) {
        if (face_selection.second < minZ || minZ == -1) {
            selected_arrow = -1;
            selected_face = face_selection.first.first;
            
            if (selected_model != face_selection.first.second) {
                vertex_render_uniforms.selected_vertices.clear();
            }
            
            selected_model = face_selection.first.second;
            minZ = face_selection.second;
            
            Face face = scene_models_faces_[selected_face];
            
            nothing_clicked = false;
        }
    }
    
    if (edge_selection.first.first.first != -1) {
        if (edge_selection.second < minZ || minZ == -1) {
            selected_arrow = -1;
            selected_face = -1;
            selected_edge.x = edge_selection.first.first.first;
            selected_edge.y = edge_selection.first.first.second;
            
            if (selected_model != edge_selection.first.second) {
                vertex_render_uniforms.selected_vertices.clear();
            }
            
            selected_model = edge_selection.first.second;
            minZ = edge_selection.second;
        }
    }

    if (vertex_selection.first.first != -1) {
        if (vertex_selection.second < minZ || minZ == -1) {
            selected_arrow = -1;
            selected_face = -1;
            selected_edge.x = -1;
            selected_edge.y = -1;
            
            if (selected_model != vertex_selection.first.second) {
                vertex_render_uniforms.selected_vertices.clear();
            }
            
            selected_model = vertex_selection.first.second;
            minZ = vertex_selection.second;
            
            bool in1 = false;
            if (keypresses_.shift) {
                for (int i = 0; i < vertex_render_uniforms.selected_vertices.size(); i++) {
                    if (vertex_selection.first.first == vertex_render_uniforms.selected_vertices[i]) {
                        in1 = true;
                        vertex_render_uniforms.selected_vertices.erase(vertex_render_uniforms.selected_vertices.begin() + i);
                        break;
                    }
                }
            } else {
                vertex_render_uniforms.selected_vertices.clear();
            }
            if (!in1) vertex_render_uniforms.selected_vertices.push_back(vertex_selection.first.first);

            nothing_clicked = false;
        }
    }
    
    if (nothing_clicked && !keypresses_.shift) {
        selected_arrow = -1;
        selected_model = -1;
        selected_face = -1;
        selected_edge = -1;
        vertex_render_uniforms.selected_vertices.clear();
    } else {
        if (selected_face != -1) {
            Face face = scene_models_faces_[selected_face];
            bool in1 = false;
            bool in2 = false;
            bool in3 = false;
            if (keypresses_.shift) {
                for (int i = 0; i < vertex_render_uniforms.selected_vertices.size(); i++) {
                    if (face.vertices[0] == vertex_render_uniforms.selected_vertices[i]) in1 = true;
                    if (face.vertices[1] == vertex_render_uniforms.selected_vertices[i]) in2 = true;
                    if (face.vertices[2] == vertex_render_uniforms.selected_vertices[i]) in3 = true;
                }
            } else {
                vertex_render_uniforms.selected_vertices.clear();
            }
            if (!in1) vertex_render_uniforms.selected_vertices.push_back(face.vertices[0]);
            if (!in2) vertex_render_uniforms.selected_vertices.push_back(face.vertices[1]);
            if (!in3) vertex_render_uniforms.selected_vertices.push_back(face.vertices[2]);
            
            if (vertex_render_uniforms.selected_vertices.size() > 3) {
                selected_face = -1;
            }
        } else if (selected_edge.x != -1) {
            bool in1 = false;
            bool in2 = false;
            if (keypresses_.shift) {
                for (int i = 0; i < vertex_render_uniforms.selected_vertices.size(); i++) {
                    if (selected_edge.x == vertex_render_uniforms.selected_vertices[i]) in1 = true;
                    if (selected_edge.y == vertex_render_uniforms.selected_vertices[i]) in2 = true;
                }
            } else {
                vertex_render_uniforms.selected_vertices.clear();
            }
            if (!in1) vertex_render_uniforms.selected_vertices.push_back(selected_edge.x);
            if (!in2) vertex_render_uniforms.selected_vertices.push_back(selected_edge.y);
            
            if (vertex_render_uniforms.selected_vertices.size() > 2) {
                selected_edge.x = -1;
                selected_edge.y = -1;
            }

            nothing_clicked = false;
        }
    }
    
    vertex_render_uniforms.num_selected_vertices = vertex_render_uniforms.selected_vertices.size();
}

void EditFEVScheme::SelectVerticesInDrag() {
    selected_arrow = -1;
    selected_face = -1;
    selected_edge = -1;
    if (!keypresses_.shift) {
        selected_model = -1;
        vertex_render_uniforms.selected_vertices.clear();
    }
    
    float left = drag_size.x > 0 ? click_loc_.x : click_loc_.x + drag_size.x;
    float right = drag_size.x > 0 ? click_loc_.x + drag_size.x : click_loc_.x;
    float down = drag_size.y > 0 ? click_loc_.y : click_loc_.y + drag_size.y;
    float up = drag_size.y > 0 ? click_loc_.y + drag_size.y : click_loc_.y;
    
    int vid = 0;
    for (int mid = 0; mid < scene_->NumModels(); mid++) {
        if (selected_model != -1) {
            mid = selected_model;
            vid = scene_->GetModel(mid)->VertexStart();
        }
        Model *m = scene_->GetModel(mid);
        int vid_end = vid + m->NumVertices();
        
        for (; vid < vid_end; vid++) {
            Vertex vertex = scene_models_projected_vertices_[vid];
            
            if (vertex.x > left && vertex.x < right && vertex.y > down && vertex.y < up) {
                if (selected_model == -1) {
                    selected_model = mid;
                }
                
                vertex_render_uniforms.selected_vertices.push_back(vid);
            }
        }
        
        if (selected_model != -1) {
            break;
        }
    }
    
    vertex_render_uniforms.num_selected_vertices = vertex_render_uniforms.selected_vertices.size();
}

void EditFEVScheme::SetControlsOrigin() {
    if (!vertex_render_uniforms.selected_vertices.empty()) {
        simd_float3 avg = simd_make_float3(0, 0, 0);
        for (int i = 0; i < vertex_render_uniforms.selected_vertices.size(); i++) {
            avg.x += scene_models_vertices_[vertex_render_uniforms.selected_vertices[i]].x;
            avg.y += scene_models_vertices_[vertex_render_uniforms.selected_vertices[i]].y;
            avg.z += scene_models_vertices_[vertex_render_uniforms.selected_vertices[i]].z;
        }
        controls_origin_ = simd_make_float3(avg.x/vertex_render_uniforms.selected_vertices.size(), avg.y/vertex_render_uniforms.selected_vertices.size(), avg.z/vertex_render_uniforms.selected_vertices.size());
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
            
            Model *model = scene_->GetModel(selected_model);
            
            for (int i = 0; i < vertex_render_uniforms.selected_vertices.size(); i++) {
                unsigned long modelVertexID = vertex_render_uniforms.selected_vertices[i] - model->VertexStart();
                model->MoveVertexBy(modelVertexID, x_vec, y_vec, z_vec);
            }
            
            should_reset_static_buffers = true;
        } else {
            float relx = ((float) (x) / (float) window_width_)*2 - 1;
            float rely = -(((float) (y) / (float) window_height_)*2 - 1);
            drag_size = simd_make_float2(relx - click_loc_.x, rely - click_loc_.y);
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


void EditFEVScheme::StartJoinModels() {
    joinModelA = selected_model;
    int vstart = scene_->GetModel(selected_model)->VertexStart();
    for (int i = 0; i < vertex_render_uniforms.selected_vertices.size(); i++) {
        joinAvids.push_back(vertex_render_uniforms.selected_vertices[i] - vstart);
    }
    
    selected_arrow = -1;
    selected_model = -1;
    selected_edge = -1;
    selected_face = -1;
    vertex_render_uniforms.selected_vertices.clear();
    vertex_render_uniforms.num_selected_vertices = 0;
}

void EditFEVScheme::JoinModels() {
    joinModelB = selected_model;
    int vstart = scene_->GetModel(selected_model)->VertexStart();
    for (int i = 0; i < vertex_render_uniforms.selected_vertices.size(); i++) {
        joinBvids.push_back(vertex_render_uniforms.selected_vertices[i] - vstart);
    }
    
    if (joinModelA != joinModelB && joinAvids.size() == joinBvids.size()) {
        DragonflyUtils::JoinModels(scene_->GetModel(joinModelA), scene_->GetModel(joinModelB), scene_->GetModelUniforms(joinModelA), scene_->GetModelUniforms(joinModelB), joinAvids, joinBvids);
        
        scene_vertex_length_ -= joinBvids.size();
        scene_node_length_ -= scene_->GetModel(joinModelB)->NumNodes();
        scene_->RemoveModel(joinModelB);
        should_reset_empty_buffers = true;
        should_reset_static_buffers = true;
    }
    
    selected_arrow = -1;
    selected_model = -1;
    selected_edge = -1;
    selected_face = -1;
    vertex_render_uniforms.selected_vertices.clear();
    vertex_render_uniforms.num_selected_vertices = 0;
    
    joinModelA = -1;
    joinModelB = -1;
    joinAvids.clear();
    joinBvids.clear();
}

void EditFEVScheme::RightClickPopup() {
    ImVec2 pixel_loc = ImVec2(window_width_ * (rightclick_popup_loc_.x+1)/2 - UI_start_.x, window_height_ * (2-(rightclick_popup_loc_.y+1))/2 - UI_start_.y);
    ImGui::SetCursorPos(pixel_loc);
    
    num_right_click_buttons_ = 0;
    
    if (selected_face != -1 || selected_edge.x != -1) {
        num_right_click_buttons_++;
        if (ImGui::Button("Add Vertex", ImVec2(button_size_.x, button_size_.y))) {
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
        pixel_loc.y += button_size_.y;
        ImGui::SetCursorPos(ImVec2(pixel_loc.x, pixel_loc.y));
    }
    
    if (selected_face != -1 || vertex_render_uniforms.selected_vertices.size() == 1) {
        num_right_click_buttons_++;
        if (ImGui::Button("Delete", ImVec2(button_size_.x, button_size_.y))) {
            render_rightclick_popup_ = false;
            
            Model* m = scene_->GetModel(selected_model);
            if (selected_face != -1) {
                m->RemoveFace(selected_face - m->FaceStart());
                scene_face_length_--;
            } else {
                m->RemoveVertex(vertex_render_uniforms.selected_vertices[0] - m->VertexStart());
                vertex_render_uniforms.selected_vertices.clear();
                scene_vertex_length_--;
            }
            
            should_reset_empty_buffers = true;
            should_reset_static_buffers = true;
        }
        pixel_loc.y += button_size_.y;
        ImGui::SetCursorPos(ImVec2(pixel_loc.x, pixel_loc.y));
    }
    
    if (vertex_render_uniforms.selected_vertices.size() == 3 && selected_face == -1) {
        num_right_click_buttons_++;
        if (ImGui::Button("Make Face", ImVec2(button_size_.x, button_size_.y))) {
            render_rightclick_popup_ = false;
            
            Model* m = scene_->GetModel(selected_model);
            int v0 = vertex_render_uniforms.selected_vertices[0] - m->VertexStart();
            int v1 = vertex_render_uniforms.selected_vertices[1] - m->VertexStart();
            int v2 = vertex_render_uniforms.selected_vertices[2] - m->VertexStart();
            m->MakeFace(v0, v1, v2, simd_make_float4(1, 1, 1, 1));
            
            scene_face_length_++;
            should_reset_empty_buffers = true;
            should_reset_static_buffers = true;
        }
        pixel_loc.y += button_size_.y;
        ImGui::SetCursorPos(ImVec2(pixel_loc.x, pixel_loc.y));
    }
    
    if (vertex_render_uniforms.selected_vertices.size() > 0 && joinModelA == -1) {
        num_right_click_buttons_++;
        if (ImGui::Button("Join With", ImVec2(button_size_.x, button_size_.y))) {
            render_rightclick_popup_ = false;
            
            StartJoinModels();
        }
        pixel_loc.y += button_size_.y;
        ImGui::SetCursorPos(ImVec2(pixel_loc.x, pixel_loc.y));
    } else if (vertex_render_uniforms.selected_vertices.size() > 0) {
        num_right_click_buttons_++;
        if (ImGui::Button("Join", ImVec2(button_size_.x, button_size_.y))) {
            render_rightclick_popup_ = false;
            
            JoinModels();
        }
        pixel_loc.y += button_size_.y;
        ImGui::SetCursorPos(ImVec2(pixel_loc.x, pixel_loc.y));
    }
    

    rightclick_popup_size_ = simd_make_float2((button_size_.x)/(float)(window_width_/2), (button_size_.y * num_right_click_buttons_)/(float)(window_height_/2));
}

void EditFEVScheme::VertexEditMenu() {
    Model *model = scene_->GetModel(selected_model);
    
    ImGui::Text("Selected Model ID: %i", selected_model);
    ImGui::SetCursorPos(ImVec2(20, 30));
    ImGui::Text("Selected Vertex ID: %lu", vertex_render_uniforms.selected_vertices[0] - model->VertexStart());
    
    int current_y = 60;
    
    std::vector<unsigned long> linked_nodes0 = model->GetLinkedNodes(vertex_render_uniforms.selected_vertices[0] - model->VertexStart());
    bool same_links = true;
    for (int i = 1; i < vertex_render_uniforms.selected_vertices.size(); i++) {
        std::vector<unsigned long> linked_nodes = model->GetLinkedNodes(vertex_render_uniforms.selected_vertices[i] - model->VertexStart());
        if (linked_nodes[0] != linked_nodes0[0] || linked_nodes.size() != linked_nodes0.size() || (linked_nodes0.size() > 1 && linked_nodes[1] != linked_nodes0[1])) {
            same_links = false;
            break;
        }
    }
    if (same_links) {
        for (int i = 0; i < linked_nodes0.size(); i++) {
            ImGui::SetCursorPos(ImVec2(30, current_y));
            ImGui::Text("Linked to node %lu", linked_nodes0[i]);
            
            if (linked_nodes0.size() > 1) {
                ImGui::SetCursorPos(ImVec2(150, current_y));
                if (ImGui::Button("Unlink")) {
                    for (int j = 0; j < vertex_render_uniforms.selected_vertices.size(); j++) {
                        model->UnlinkNodeAndVertex(vertex_render_uniforms.selected_vertices[j] - model->VertexStart(), linked_nodes0[i]);
                    }
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
                for (int i = 0; i < vertex_render_uniforms.selected_vertices.size(); i++) {
                    model->LinkNodeAndVertex(vertex_render_uniforms.selected_vertices[i] - model->VertexStart(), nid);
                    
                }
                should_reset_static_buffers = true;
            }
        }
    } else {
        ImGui::SetCursorPos(ImVec2(30, current_y));
        ImGui::Text("Mixed node links");
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
    if (selected_edge.x != -1) {
        EdgeEditMenu();
    } else if (selected_face != -1) {
        FaceEditMenu();
    } else if (!vertex_render_uniforms.selected_vertices.empty()) {
        VertexEditMenu();
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
    
    bool should_show_drag = left_mouse_down_ && dist2to3(drag_size, simd_make_float3(0, 0, 0)) > 0.05;
    if (should_show_drag) {
        ImVec2 start;
        if (drag_size.x < 0) {
            start.x = window_width_*((click_loc_.x + drag_size.x)+1)/2;
        } else {
            start.x = window_width_*((click_loc_.x)+1)/2;
        }
        if (drag_size.y > 0) {
            start.y = window_height_*(2-(click_loc_.y + drag_size.y+1))/2;
        } else {
            start.y = window_height_*(2-(click_loc_.y+1))/2;
        }
        
        ImGui::SetNextWindowPos(start);
        ImGui::SetNextWindowSize(ImVec2(abs(window_width_*drag_size.x/2), abs(window_height_*(-drag_size.y/2))));
        ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.0f, 0.4f, 0.8f, 0.3f));
        
        ImGui::Begin("drag", &should_show_drag, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoResize);
        
        ImGui::PopStyleColor();
        
        ImGui::End();
    }
}

void EditFEVScheme::BuildUI() {
    MainWindow();
    
    RightMenu();
}

void EditFEVScheme::SetBufferContents(Vertex *smv, Vertex *smpv, Face *smf, Node *smn, Vertex *smpn, Vertex *cmv, Vertex *cmpv, Face *cmf) {
    Scheme::SetBufferContents(smv, smpv, smf, smn, smpn, cmv, cmpv, cmf);
    SetArrowProjections();
}
