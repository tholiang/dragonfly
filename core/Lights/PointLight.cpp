#include "PointLight.h"

LightUnit PointLightIntensity(float max_intensity, vec_float4 color, vec_float3 point) {
    float d = Magnitude(point);
    return {
        unit_vector(point),
        color,
        max_intensity / (d*d)
    };
}

PointLight::PointLight() : max_intensity_(1), color_(vec_make_float4(1, 1, 1, 1)) {
    simple_convertible_ = true;
    intensity_field_ = std::bind(PointLightIntensity, max_intensity_, color_, std::placeholders::_1);
}

PointLight::PointLight(float max_intensity, vec_float4 color) : max_intensity_(max_intensity), color_(color) {
    simple_convertible_ = true;
    intensity_field_ = std::bind(PointLightIntensity, max_intensity_, color_, std::placeholders::_1);
}

SimpleLight PointLight::ToSimpleLight(Basis b) {
    SimpleLight ret;
    ret.b = b;
    ret.max_intensity = max_intensity_;
    ret.color = color_;
    ret.distance_multiplier = {1, 0, 0};
    ret.angle_multiplier = {0, 0, 1};
    return ret;
}