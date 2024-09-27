#ifndef PointLight_h
#define PointLight_h

#include "Light.h"

// a light that emits light in all directions from its origin
class PointLight: public Light {
public:
    PointLight();
    PointLight(float max_intensity, vec_float4 color);

    SimpleLight ToSimpleLight(Basis b);
private:
    float max_intensity_;
    vec_float4 color_;
};

#endif // PointLight_h