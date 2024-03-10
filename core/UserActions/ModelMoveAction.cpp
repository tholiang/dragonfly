//
//  VertexMoveAction.cpp
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#include "ModelMoveAction.h"
#include <iostream>

ModelMoveAction::ModelMoveAction(Scene *scene, int mid) : scene_(scene), mid_(mid) {
    type_ = "Model Move Action";
}

void ModelMoveAction::BeginRecording() {
    initial_location_ = scene_->GetModelPosition(mid_);
    
    recording_ = true;
}

void ModelMoveAction::EndRecording() {
    simd_float3 new_loc = scene_->GetModelPosition(mid_);
    movement_vector_.x = new_loc.x - initial_location_.x;
    movement_vector_.y = new_loc.y - initial_location_.y;
    movement_vector_.z = new_loc.z - initial_location_.z;
    
    recording_ = false;
}

void ModelMoveAction::Do() {
    scene_->MoveModelBy(mid_, movement_vector_.x, movement_vector_.y, movement_vector_.z);
}

void ModelMoveAction::Undo() {
    scene_->MoveModelBy(mid_, -movement_vector_.x, -movement_vector_.y, -movement_vector_.z);
}

ModelMoveAction::~ModelMoveAction () {
    
}
