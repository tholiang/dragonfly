# Basic Datatypes

## vecs
vecs are fixed size packings of a given datatype. These currently include:
```
vec_float2 = {float x, float y}
vec_float3 = {float x, float y, float z}
vec_float4 = {float x, float y, float z, float w}
vec_int2 = {int x, int y}
vec_int3 = {int x, int y, int z}
vec_int4 = {int x, int y, int z, int w}
```

vecs can be initialized via `vec_make_*` functions, where the `*` describes the wanted vec (ex `vec_make_float2`)

`vec_float3` also currently supports vector addition and subtraction

## bases
a basis represents orientation via three `vec_float3`s

these are used to describe relative **spaces**