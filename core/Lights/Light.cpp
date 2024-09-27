#include "Light.h"

SimpleLight Light::ToSimpleLight(Basis b) {
    SimpleLight ret;
    ret.b = b;
    ret.max_intensity = 0;
    return ret;
}

LightUnit Light::GetIntensity(vec_float3 p) {
    return intensity_field_(p);
}