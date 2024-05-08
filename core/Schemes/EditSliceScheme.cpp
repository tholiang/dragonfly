//
//  SliceEditScheme.cpp
//  dragonfly
//
//  Created by Thomas Liang on 1/31/23.
//

#include "EditSliceScheme.h"
#include "../Pipelines/ComputePipeline.h"

using namespace DragonflyUtils;

EditSliceScheme::EditSliceScheme() {
    type = SchemeType::EditSlice;
    
    should_render.faces = false;
    should_render.edges = false;
    should_render.vertices = false;
    should_render.nodes = false;
    should_render.slices = true;
    
    button_size_ = ImVec2(100, 30);
}

EditSliceScheme::~EditSliceScheme() {
    
}

void EditSliceScheme::SetDrawing() {
    mode = Drawing;
}

void EditSliceScheme::SetEditing() {
    mode = Editing;
}

vector_float2 EditSliceScheme::screen_to_eloc(vector_float2 loc) {
    vector_float4 edit_window = GetEditWindow();
    vector_float2 eloc = loc;
    
    eloc.x -= edit_window.x;
    eloc.y -= edit_window.y;
    eloc.x /= edit_window.z;
    eloc.y /= edit_window.w;
    
    return eloc;
}

void EditSliceScheme::CreateDotAtClick(vector_float2 click_loc) {
    SliceAttributes attr = slice_->GetAttributes();
    float scale = attr.height / 2;
    if (attr.height < attr.width) {
        scale = attr.width / 2;
    }
    
    float ewidth = window_width_ - right_menu_width_;
    float eheight = window_height_ - UI_start_.y;
    float eratio = ewidth/eheight;
    
    vector_float2 eloc = screen_to_eloc(click_loc);
    float x,y;
    
    if (eratio < 1) {
        x = eloc.x * scale;
        y = scale * eloc.y / eratio;
    } else {
        x = eloc.x * scale * eratio;
        y =  eloc.y * scale;
    }
    if (x > scale || y > scale || x < -scale || y < -scale) {
        std::cout<<"out of bounds"<<std::endl;
        return;
    }
    
    
    slice_->MakeDot(x, y);
    
    if (first_dot == -1) {
        first_dot = slice_->NumDots()-1;
    }
    
    if (last_dot != -1) {
        slice_->MakeLine(last_dot, slice_->NumDots()-1);
    }
    last_dot = slice_->NumDots()-1;
    
    
    CalculateNumSceneDots();
    CalculateNumSceneLines();
    should_reset_empty_buffers = true;
    should_reset_static_buffers = true;
}

int EditSliceScheme::DotClicked(vector_float2 loc) {
    Slice *s = scene_->GetSlice(slice_id);
    vector_float4 edit_window = GetEditWindow();
    float ewidth = window_width_ - right_menu_width_;
    float eheight = window_height_ - UI_start_.y;
    float eratio = ewidth/eheight;
    
    for (int i = 0; i < s->NumDots(); i++) {
        Dot *d = s->GetDot(i);
        
        float x,y;
        
        SliceAttributes attr = slice_->GetAttributes();
        float scale = attr.height / 2;
        if (attr.height < attr.width) {
            scale = attr.width / 2;
        }
        
        if (eratio < 1) {
            x = d->x / scale;
            y = eratio * d->y / scale;
        } else {
            x = (d->x / scale) / eratio;
            y =  d->y / scale;
        }
        
        x *= edit_window.z;
        y *= edit_window.w;
        x += edit_window.x;
        y += edit_window.y;
        
        float x_min = x-0.007;
        float x_max = x+0.007;
        float y_min = y-0.007 * aspect_ratio_;
        float y_max = y+0.007 * aspect_ratio_;
        
        if (loc.x <= x_max && loc.x >= x_min && loc.y <= y_max && loc.y >= y_min) {
            return i;
        }
    }
    
    return -1;
}

int EditSliceScheme::LineClicked(vector_float2 loc) {
    Slice *s = scene_->GetSlice(slice_id);
    vector_float4 edit_window = GetEditWindow();
    float ewidth = window_width_ - right_menu_width_;
    float eheight = window_height_ - UI_start_.y;
    float eratio = ewidth/eheight;
    
    for (int i = 0; i < s->NumLines(); i++) {
        Line *l = s->GetLine(i);
        
        Dot *d1 = s->GetDot(l->d1);
        Dot *d2 = s->GetDot(l->d2);
        
        float x1,y1,x2,y2;
        
        SliceAttributes attr = slice_->GetAttributes();
        float scale = attr.height / 2;
        if (attr.height < attr.width) {
            scale = attr.width / 2;
        }
        
        if (eratio < 1) {
            x1 = d1->x / scale;
            y1 = eratio * d1->y / scale;
            x2 = d2->x / scale;
            y2 = eratio * d2->y / scale;
        } else {
            x1 = (d1->x / scale) / eratio;
            y1 = d1->y / scale;
            x2 = (d2->x / scale) / eratio;
            y2 = d2->y / scale;
        }
        
        x1 *= edit_window.z;
        y1 *= edit_window.w;
        x1 += edit_window.x;
        y1 += edit_window.y;
        
        x2 *= edit_window.z;
        y2 *= edit_window.w;
        x2 += edit_window.x;
        y2 += edit_window.y;
        
        vector_float2 edgeVec = vector_make_float2(x1-x2, y1-y2);
        float mag = sqrt(pow(edgeVec.x, 2) + pow(edgeVec.y, 2));
        if (mag == 0) {
            continue;
        }
        edgeVec.x /= mag;
        edgeVec.y /= mag;
        
        edgeVec.x *= 0.01;
        edgeVec.y *= 0.01;
        
        Dot d1plus = vector_make_float2(x1+edgeVec.y, y1-edgeVec.x);
        Dot d1sub = vector_make_float2(x1-edgeVec.y, y1+edgeVec.x);
        Dot d2plus = vector_make_float2(x2+edgeVec.y, y1-edgeVec.x);
        Dot d2sub = vector_make_float2(x2-edgeVec.y, y2+edgeVec.x);
        
        if (InTriangle2D(loc, d1plus, d1sub, d2plus) || InTriangle2D(loc, d1sub, d2sub, d2plus)) {
            return i;
        }
    }
    
    return -1;
}

bool EditSliceScheme::ClickOnScene(vector_float2 loc) {
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

void EditSliceScheme::HandleSelection(vector_float2 loc) {
    if (mode == Editing) {
        Slice *s = scene_->GetSlice(slice_id);
        int dot_selection = DotClicked(loc);
        int line_selection = LineClicked(loc);
        
        if (dot_selection >= 0) {
            selected_vertices.clear();
            selected_vertices.push_back(dot_selection);
            held_dot = dot_selection;
        } else if (line_selection >= 0) {
            selected_line = line_selection;
            selected_vertices.clear();
            selected_vertices.push_back(s->GetLine(selected_line)->d1);
            selected_vertices.push_back(s->GetLine(selected_line)->d2);
        } else {
            selected_line = -1;
            selected_vertices.clear();
        }
    }
}

void EditSliceScheme::SelectDotsInDrag() {
    
}

void EditSliceScheme::RightClickPopup() {
    ImVec2 pixel_loc = ImVec2(window_width_ * (rightclick_popup_loc_.x+1)/2 - UI_start_.x, window_height_ * (2-(rightclick_popup_loc_.y+1))/2 - UI_start_.y);
    ImGui::SetCursorPos(pixel_loc);
    
    num_right_click_buttons_ = 0;
    
    
    rightclick_popup_size_ = vector_make_float2((button_size_.x)/(float)(window_width_/2), (button_size_.y * num_right_click_buttons_)/(float)(window_height_/2));
}

void EditSliceScheme::RightMenu() {
    ImGui::SetNextWindowPos(ImVec2(window_width_ - right_menu_width_, UI_start_.y));
    ImGui::SetNextWindowSize(ImVec2(right_menu_width_, window_height_ - UI_start_.y));
    ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0.0f, 0.0f, 0.0f, 255.0f));
    ImGui::Begin("side", &show_UI, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoResize);
    
    ImGui::SetCursorPos(ImVec2(20, 10));
    if (mode == Drawing) {
        ImGui::Text("Drawing");
        ImGui::SetCursorPos(ImVec2(20, 30));
        
        if (ImGui::Button("Finish")) {
            Slice *s = scene_->GetSlice(slice_id);
            
            if (first_dot != -1 && first_dot != last_dot) {
                s->MakeLine(first_dot, last_dot);
            }
            
            CalculateNumSceneLines();
            should_reset_static_buffers = true;
            
            mode = Editing;
        }
    } else if (mode == Editing) {
        if (selected_vertices.size() == 1) {
            DotEditMenu();
        } else if (selected_line != -1) {
            LineEditMenu();
        } else {
            ImGui::Text("Editing");
            ImGui::SetCursorPos(ImVec2(20, 30));
            ImGui::Text("Nothing Selected");
        }
    }
    
    ImGui::PopStyleColor();
    
    ImGui::End();
}

void EditSliceScheme::DotEditMenu() {
    Slice *s = scene_->GetSlice(slice_id);
    ImGui::Text("Selected Dot: ", selected_vertices[0]);
    
    ImGui::SetCursorPos(ImVec2(20, 30));
    
    if (ImGui::Button("Delete")) {
        s->RemoveDotAndMergeLines(selected_vertices[0]);
        
        CalculateNumSceneDots();
        CalculateNumSceneLines();
        should_reset_static_buffers = true;
        
        selected_vertices.clear();
    }
}

void EditSliceScheme::LineEditMenu() {
    Slice *s = scene_->GetSlice(slice_id);
    ImGui::Text("Selected Line: ", selected_line);
    
    ImGui::SetCursorPos(ImVec2(20, 30));
    
    if (ImGui::Button("Add Dot To Edge")) {
        s->AddDotToLine(selected_line);
        
        Line *e = s->GetLine(selected_line);
        
        selected_vertices.clear();
        selected_vertices.push_back(e->d1);
        selected_vertices.push_back(e->d2);
        
        CalculateNumSceneDots();
        CalculateNumSceneLines();
        should_reset_static_buffers = true;
    }
}

void EditSliceScheme::MainWindow() {
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

void EditSliceScheme::HandleMouseMovement(float x, float y, float dx, float dy) {
    if (held_dot != -1) {
        x = ((float) x / (float) window_width_)*2 - 1;
        y = -(((float) y / (float) window_height_)*2 - 1);
        
        Slice *s = scene_->GetSlice(slice_id);
        Dot *d = s->GetDot(held_dot);
        
        float ewidth = window_width_ - right_menu_width_;
        float eheight = window_height_ - UI_start_.y;
        float eratio = ewidth/eheight;
        
        vector_float2 eloc = screen_to_eloc(vector_make_float2(x, y));
        
        SliceAttributes attr = slice_->GetAttributes();
        float scale = attr.height / 2;
        if (attr.height < attr.width) {
            scale = attr.width / 2;
        }
        
        if (eratio < 1) {
            d->x = eloc.x * scale;
            d->y = scale * eloc.y / eratio;
        } else {
            d->x = eloc.x * scale * eratio;
            d->y =  eloc.y * scale;
        }
        
        should_reset_static_buffers = true;
    }
}

void EditSliceScheme::BuildUI() {
    MainWindow();
    
    RightMenu();
}

void EditSliceScheme::HandleMouseDown(vector_float2 loc, bool left) {
    Scheme::HandleMouseDown(loc, left);
    
    loc.x = ((float) loc.x / (float) window_width_)*2 - 1;
    loc.y = -(((float) loc.y / (float) window_height_)*2 - 1);
    
    drag_size.x = 0;
    drag_size.y = 0;
    
    if (!left) {
        if (selected_vertices.size() > 0) {
            rightclick_popup_loc_ = loc;
            render_rightclick_popup_ = true;
        } else {
            render_rightclick_popup_ = false;
        }
    } else {
        if (mode == Drawing && ClickOnScene(loc)) {
            CreateDotAtClick(loc);
        }
    }
}

void EditSliceScheme::HandleMouseUp(vector_float2 loc, bool left) {
    Scheme::HandleMouseUp(loc, left);
    
    loc.x = ((float) loc.x / (float) window_width_)*2 - 1;
    loc.y = -(((float) loc.y / (float) window_height_)*2 - 1);
    
    if (left) {
        if (!(render_rightclick_popup_ && InRectangle(rightclick_popup_loc_, rightclick_popup_size_, loc))) {
            render_rightclick_popup_ = false;
        }
        
        if (dist2to3(drag_size, vector_make_float3(0, 0, 0)) > 0.05) {
            SelectDotsInDrag();
        }
        
        held_dot = -1;
    }
    
    drag_size.x = 0;
    drag_size.y = 0;
}

void EditSliceScheme::SetSliceID(int sid) {
    slice_id = sid;
    
    Slice *s = scene_->GetSlice(sid);
    num_edit_slice_dots = s->NumDots();
    num_edit_slice_lines = s->NumLines();
    slice_ = s;
    
    should_reset_static_buffers = true;
    should_reset_empty_buffers = true;
}

int EditSliceScheme::GetSliceID() {
    return slice_id;
}

Slice *EditSliceScheme::GetSlice() {
    return slice_;
}

vector_float4 EditSliceScheme::GetEditWindow() {
    vector_float4 window;
    window.x = float(-right_menu_width_)/ window_width_;
    window.y = float(UI_start_.y) / window_height_;
    window.z = float(window_width_ - right_menu_width_)/(window_width_);
    window.w = float(window_height_ - UI_start_.y)/(window_height_);
    
    return window;
}

void EditSliceScheme::CalculateNumSceneDots() {
    num_edit_slice_dots = slice_->NumDots();
}

void EditSliceScheme::CalculateNumSceneLines() {
    num_edit_slice_lines = slice_->NumLines();
}

unsigned long EditSliceScheme::NumSceneSlices() {
    return 1;
}

unsigned long EditSliceScheme::NumSceneDots() {
    return num_edit_slice_dots;
}

unsigned long EditSliceScheme::NumSceneLines() {
    return num_edit_slice_lines;
}

void EditSliceScheme::SetSliceDotBuffer(Dot *buf) {
    for (int j = 0; j < slice_->NumDots(); j++) { // iterate through dots
        // add dot to buffer
        buf[j] = *slice_->GetDot(j);
    }
}

void EditSliceScheme::SetSliceLineBuffer(vector_int2 *buf, unsigned long dot_start) {
    for (int j = 0; j < slice_->NumLines(); j++) { // iterate through current models faces
        // copy line
        Line l = *slice_->GetLine(j);
        // add dot start to original line dids
        l.d1 += dot_start;
        l.d2 += dot_start;
        
        // TODO: MAYBE CHANGE EDGE/LINE FORMAT
        buf[j] = vector_make_int2(l.d1, l.d2);
    }
}

void EditSliceScheme::SetSliceAttributesBuffer(SliceAttributes *buf) {
    buf[0] = slice_->GetAttributes();
}
