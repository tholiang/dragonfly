# buffers

the following buffers are used to share data between the cpu and gpu

```

```

## compiled compute buffers

the primary outputs of the compute are three buffers - containing the vertex, face, and edge data, respectively, for everything to be rendered on screen

these buffers are split by panel order, but packed tightly

for face and edge buffers, vertex indices are directly addressing the compiled vertex buffer

relative indices for vertex sub-buffers can be computed from PanelInfoBuffer information