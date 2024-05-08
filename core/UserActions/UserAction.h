//
//  UserAction.h
//  dragonfly
//
//  Created by Thomas Liang on 5/30/22.
//

#ifndef UserAction_h
#define UserAction_h

#include <stdio.h>
#include <vector>
#include <string>

#include "Utils/Vec.h"
using namespace Vec;

class UserAction {
public:
    UserAction();
    bool IsRecording();
    virtual void BeginRecording() = 0;
    virtual void EndRecording() = 0;
    virtual void Do() = 0;
    virtual void Undo() = 0;
    virtual ~UserAction();
    std::string Type();
protected:
    bool recording_;
    std::string type_ = "";
};

#endif /* UserAction_h */
