# lights

at the raw level, lights are represented as intensity fields:

```
light = {
    (vec_float3)->UnitLight intensity_field;
}
```

### Unit Light

A unit light is a single direction vector, along with a color and an intensity

## intensity fields

given some point, an intensity field will return a color and direction describing the light's behavior at that point'

## lights in a scene

lights, like models, exist in a scene along with a basis

points are translated to this basis before being fed into a light's intensity field

## lighting computation

the way the renderer will compute lighting from intensity fields depends on the approach

### flat shading

to compute lighting for a given face, we provide the face average (center of the face) into the intensity field

with the outputted direction vector, we can calculate the "reflected" light vector from the face normal

finally, we use the angle between the reflected light vector and the camera vector to get a color value for the face


## simple lights

intensity field shading is too complex to viably be calculated on the gpu, so we also provide a simpler data structure for lighting

to determine a unit light from a simple light at a point, we use the point's distance from the light and the angle to it

the intensity at the point is determined by a distance and angle falloff

```
SimpleLight = {
    float max_intensity
    vec_float4 color
    vec_float3 distance_falloff_function
    vec_float3 angle_falloff_function
}
```

these `vec_float3`'s describe coefficients of the quadratic polynomial for the distance and angle multipliers

```
distance_falloff_function = (a, b, c)
distance = d
d_multiplier = a(1/d^2) + b(1/d) + c
```

the angle multiplier is calculated the same way

we first translate a point to the lights basis, then calculate distance using euclidean distance from `(0, 0, 0)` and angle from `(1, 0, 0)`

then the intensity at the point is `max_intensity * d_multiplier * a_multipler`
