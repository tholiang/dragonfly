//
//  VertexMoveAction.cpp
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#include "VertexMoveAction.h"

VertexMoveAction::VertexMoveAction(Model *m, std::vector<int> vids) : model_(m), vids_(vids) {
    type_ = "Vertex Move Action";
}

void VertexMoveAction::BeginRecording() {
    initial_location_ = model_->GetVertex(vids_[0]);

    recording_ = true;
}

void VertexMoveAction::EndRecording() {
    simd_float3 v = model_->GetVertex(vids_[0]);
    movement_vector_.x = v.x - initial_location_.x;
    movement_vector_.y = v.y - initial_location_.y;
    movement_vector_.z = v.z - initial_location_.z;

    recording_ = false;
}

void VertexMoveAction::Do() {
    for (int i = 0; i < vids_.size(); i++) {
        model_->MoveVertexBy(vids_[i], movement_vector_.x, movement_vector_.y, movement_vector_.z);
    }
}

void VertexMoveAction::Undo() {
    for (int i = 0; i < vids_.size(); i++) {
        model_->MoveVertexBy(vids_[i], -movement_vector_.x, -movement_vector_.y, -movement_vector_.z);
    }
}

VertexMoveAction::~VertexMoveAction () {
    
}
