//
//  EditFEVScheme.h
//  dragonfly
//
//  Created by Thomas Liang on 7/5/22.
//

#ifndef EditFEVScheme_h
#define EditFEVScheme_h

#include "Scheme.h"
#include "../UserActions/VertexMoveAction.h"
#include "../UserActions/EdgeMoveAction.h"
#include "../UserActions/FaceMoveAction.h"
#include "../UserActions/FaceAddVertexAction.h"
#include "../UserActions/EdgeAddVertexAction.h"

class EditFEVScheme : public Scheme {
private:
    int right_menu_width_ = 300;
    
    bool render_rightclick_popup_ = false;
    simd_float2 rightclick_popup_loc_;
    simd_float2 rightclick_popup_size_;
    bool rightclick_popup_clicked_ = false;
    
    Arrow *z_arrow;
    Arrow *x_arrow;
    Arrow *y_arrow;
    // z base, z tip, x base, x tip, y base, y tip
    simd_float2 arrow_projections [6];
    // z, x, y
    int selected_arrow = -1;
    int ARROW_VERTEX_SIZE = 18;
    int ARROW_FACE_SIZE = 22;
    
    int selected_face = -1;
    vector_int2 selected_edge;
    int selected_vertex = -1;
    int selected_model = -1;
    
    void CreateControlsModels();
    
    int GetVertexModel(int vid);
    
    std::pair<std::pair<int, int>, float> FaceClicked(simd_float2 loc);
    std::pair<std::pair<int, int>, float> VertexClicked(simd_float2 loc);
    std::pair<std::pair<std::pair<int, int>, int>, float> EdgeClicked(simd_float2 loc);
    
    bool ClickOnScene(simd_float2 loc);
    
    void HandleSelection(simd_float2 loc);
    
    void SetControlsOrigin();
    
    void SetArrowProjections();
    
    void AddVertexToFace (int fid, int mid);
    void AddVertexToEdge (int vid1, int vid2, int mid);
    
    void RightClickPopup();
    
    void RightMenu();
    void VertexEditMenu();
    void EdgeEditMenu();
    void FaceEditMenu();
    
    void MainWindow();
    
public:
    void HandleMouseMovement(float x, float y, float dx, float dy);
    
    void BuildUI();
    void SetBufferContents(Vertex *smv, Vertex *smpv, Face *smf, Node *smn, Vertex *smpn, Vertex *cmv, Vertex *cmpv, Face *cmf);
    
    void HandleMouseDown(simd_float2 loc, bool left);
    void HandleMouseUp(simd_float2 loc, bool left);
    
    EditFEVScheme();
    ~EditFEVScheme();
};

#endif /* EditFEVScheme_h */
