//
//  UserAction.m
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#include "UserAction.h"

UserAction::UserAction() : recording_(false) {}

bool UserAction::IsRecording() {
    return recording_;
}

std::string UserAction::Type() {
    return type_;
}

UserAction::~UserAction() {
    
}
