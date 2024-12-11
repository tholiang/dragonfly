#ifndef SceneUtils_h
#define SceneUtils_h

#include <stdio.h>
#include <iostream>
#include <cmath>

#include "Utils.h"
#include "../Modeling/Scene.h"

using namespace Vec;

namespace DragonflyUtils {
unsigned long NumSceneVertices(Scene *s);
unsigned long NumSceneDots(Scene *s);
unsigned long NumSceneNodes(Scene *s);
unsigned long NumSceneFaces(Scene *s);
unsigned long NumSceneLines(Scene *s);
}

#endif /* SceneUtils_h */