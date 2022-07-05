//
//  VertexMoveAction.m
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#include "ModelMoveAction.h"

ModelMoveAction::ModelMoveAction(std::vector<ModelUniforms> *uniforms, int mid) : uniforms_(uniforms), mid_(mid) {
    type_ = "Model Move Action";
}

void ModelMoveAction::BeginRecording() {
    initial_location_ = uniforms_->at(mid_).position;
    
    recording_ = true;
}

void ModelMoveAction::EndRecording() {
    simd_float3 new_loc = uniforms_->at(mid_).position;
    movement_vector_.x = new_loc.x - initial_location_.x;
    movement_vector_.y = new_loc.y - initial_location_.y;
    movement_vector_.z = new_loc.z - initial_location_.z;
    
    recording_ = false;
}

void ModelMoveAction::Do() {
    uniforms_->at(mid_).position.x += movement_vector_.x;
    uniforms_->at(mid_).position.y += movement_vector_.y;
    uniforms_->at(mid_).position.z += movement_vector_.z;
    
    uniforms_->at(mid_).rotate_origin.x += movement_vector_.x;
    uniforms_->at(mid_).rotate_origin.y += movement_vector_.y;
    uniforms_->at(mid_).rotate_origin.z += movement_vector_.z;
}

void ModelMoveAction::Undo() {
    uniforms_->at(mid_).position.x -= movement_vector_.x;
    uniforms_->at(mid_).position.y -= movement_vector_.y;
    uniforms_->at(mid_).position.z -= movement_vector_.z;
    
    uniforms_->at(mid_).rotate_origin.x -= movement_vector_.x;
    uniforms_->at(mid_).rotate_origin.y -= movement_vector_.y;
    uniforms_->at(mid_).rotate_origin.z -= movement_vector_.z;
}

ModelMoveAction::~ModelMoveAction () {
    
}
