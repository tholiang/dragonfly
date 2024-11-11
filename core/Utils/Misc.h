#ifndef Misc_h
#define Misc_h

#include <stdio.h>
#include <iostream>
#include <cmath>

#include "Utils.h"
#include "Vec.h"

using namespace Vec;

namespace DragonflyUtils {
struct Keys {
    bool w = false;
    bool a = false;
    bool s = false;
    bool d = false;
    bool space = false;
    bool shift = false;
    bool option = false;
    bool control = false;
    bool command = false;
};

struct Mouse {
    vec_float2 location; // ([-1, 1], [-1, 1]) xy position relative to center of window
    vec_float2 movement;
    bool left = false;
    bool right = false;
};
}

#endif // Misc_h