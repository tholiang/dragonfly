# scenes
scenes contain a collection of objects and their locations

each object is paired with a **model transform** describing the object's position and rotation in a given scene

```
model_transform = {
    Basis b
    vec_float3 rotate_origin (unused)
}
```