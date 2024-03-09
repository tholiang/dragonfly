//
//  EditModelScheme.h
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#ifndef EditModelScheme_h
#define EditModelScheme_h

#include "Scheme.h"
#include "../UserActions/ModelMoveAction.h"
#include "../Utils/Normals.h"
#include "../Utils/JoinModels.h"

class EditModelScheme : public Scheme {
private:
    // ---UI VARIABLES---
    int right_menu_width_ = 300;
    bool render_rightclick_popup_ = false;
    simd_float2 rightclick_popup_loc_;
    int num_right_click_buttons_ = 0;
    ImVec2 button_size_;
    simd_float2 rightclick_popup_size_;
    bool rightclick_popup_clicked_ = false;
    
    // ---CONTROL MODELS---
    Arrow *z_arrow;
    Arrow *x_arrow;
    Arrow *y_arrow;
    
    Rotator *z_rotator;
    Rotator *x_rotator;
    Rotator *y_rotator;
    // z base, z tip, x base, x tip, y base, y tip
    simd_float2 arrow_projections [6];
    simd_float2 rotator_projections [6];
    // z, x, y
    int selected_arrow = -1;
    int selected_rotator = -1;
    int ARROW_VERTEX_SIZE = 10;
    int ARROW_FACE_SIZE = 12;
    int ROTATOR_VERTEX_SIZE = 20;
    int ROTATOR_FACE_SIZE = 8;
    
    // ---SELECTIONS---
    int selected_model = -1;
    
    // ---ANIMATION---
    unsigned long wanted_aid = 0;
    std::pair<int, int> loopanim;
    
    // ---TEXT INPUT VARIABLES---
    std::string angle_input_x = "0";
    std::string angle_input_y = "0";
    std::string angle_input_z = "0";
    
    std::string scale_input_x = "1";
    std::string scale_input_y = "1";
    std::string scale_input_z = "1";
    
    std::string add_model_input = "-1";
    
    
    // ---CLICK HANDLERS---
    std::pair<int, float> ModelClicked(simd_float2 loc);
    bool ClickOnScene(simd_float2 loc);
    void HandleSelection(simd_float2 loc);
    void ModelEditMenu();
    
    // ---CONTROL MODELS FUNCTIONS---
    void CreateControlsModels();
    void SetControlsBasis();
    void SetArrowProjections();
    
    // ---UI RENDER FUNCTIONS---
    void RightClickPopup();
    void RightMenu();
    void MainWindow();
public:
    // ---GENERAL SCHEME FUNCTIONS---
    EditModelScheme(); // constructor
    ~EditModelScheme(); // destructor
    void Update(); // update function called every frame
    
    // ---DIRECT INPUT HANDLERS---
    void HandleMouseDown(simd_float2 loc, bool left);
    void HandleMouseUp(simd_float2 loc, bool left);
    void HandleMouseMovement(float x, float y, float dx, float dy);
    
    // ---UI RENDER---
    void BuildUI();
    
    // ---FILES---
    void SaveSelectedModelToFile(std::string path);
    
    // ---FOR COMPUTE BUFFERS---
    // setter for compute buffer to set buffer data
    void SetBufferContents(CompiledBufferKeyIndices *cki, Vertex *ccv, Face *ccf, Vertex *cmv, Node *cmn);
};

#endif /* EditModelScheme_h */
