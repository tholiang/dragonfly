# buffers

the following buffers are used to share data between the cpu and gpu

```

```

## static vs dynamic buffers

dynamic buffer's contents are expected to change often cpu side (per frame), while static buffers change infrequently

## sizing and updates

neither static nor dynamic buffers' sizes are expected to change often, but they will change relatively frequently given that this is a 3D modeling software

to prevent the need to recreate a buffer every time a vertex is added, we implement a dynamic resize similar to `std::vector`