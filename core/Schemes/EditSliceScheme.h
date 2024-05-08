//
//  SliceEditScheme.hpp
//  dragonfly
//
//  Created by Thomas Liang on 1/31/23.
//

#ifndef EditSliceScheme_h
#define EditSliceScheme_h

#include <stdio.h>

#include "Scheme.h"
#include "../Utils/Utils.h"

class EditSliceScheme : public Scheme {
private:
    enum Mode {
        Drawing,
        Editing
    };
    
    Mode mode = Drawing;
    
    int slice_id = 0;
    
    int right_menu_width_ = 300;
    
    bool render_rightclick_popup_ = false;
    vector_float2 rightclick_popup_loc_;
    int num_right_click_buttons_ = 0;
    ImVec2 button_size_;
    vector_float2 rightclick_popup_size_;
    bool rightclick_popup_clicked_ = false;
    
    Slice *slice_;
    
    vector_float2 drag_size;
    
    // drawing vars
    int first_dot = -1;
    int last_dot = -1;
    
    // editing vars
    int selected_line = -1;
    int held_dot = -1;
    
    unsigned long num_edit_slice_dots = 0;
    unsigned long num_edit_slice_lines = 0;
    
    vector_float2 screen_to_eloc(vector_float2 loc);
    
    void CreateDotAtClick(vector_float2 click_loc);
    
    int DotClicked(vector_float2 loc);
    int LineClicked(vector_float2 loc);
    
    bool ClickOnScene(vector_float2 loc);
    
    void HandleSelection(vector_float2 loc);
    
    void SelectDotsInDrag();
    
    void RightClickPopup();
    
    void RightMenu();
    void DotEditMenu();
    void LineEditMenu();
    
    void MainWindow();
    
    void CalculateNumSceneDots();
    void CalculateNumSceneLines();
    
public:
    EditSliceScheme();
    ~EditSliceScheme();
    
    void SetDrawing();
    void SetEditing();
    
    void HandleMouseMovement(float x, float y, float dx, float dy);
    
    void BuildUI();
    
    void HandleMouseDown(vector_float2 loc, bool left);
    void HandleMouseUp(vector_float2 loc, bool left);
    
    void SetSliceID(int sid);
    int GetSliceID();
    
    Slice *GetSlice();
    
    vector_float4 GetEditWindow();
    
    unsigned long NumSceneSlices();
    unsigned long NumSceneDots();
    unsigned long NumSceneLines();
    
    void SetSliceDotBuffer(Dot *buf);
    void SetSliceLineBuffer(vector_int2 *buf, unsigned long dot_start); // start of dots in cvb
    void SetSliceAttributesBuffer(SliceAttributes *buf);
};

#endif /* PlaneDrawScheme_h */
