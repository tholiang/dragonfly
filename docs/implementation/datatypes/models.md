# models
models are the standard representation of a 3D object, designed to be easily translated into renderable polygons

## vertices
vertices are the 3D points that determine the "physical" structure of a model. As a data structure, a vertex only contains three float values for its x, y, and z position

```
vertex = vec_float3 = {float x, float y, float z}
```

> models don't actually explicitly contain vertices, but instead model vertices are implicitly described via **node vertex links**

## nodes
nodes act as a skeleton of the model, allowing models to be dynamically morphable and animatable. Nodes simply contain their own **Basis**

```
node = {Basis b}
```

models must contain at least one node, called the **zero node**

> ### zero node
> the zero node is an immovable node positioned at the point `(0,0,0)` in **model space**, also with a rotation of `(0,0,0)`. Since vertices are described relative to nodes, the zero node is necessary to allow "objectively" positioned vertices (see **node vertex links** for more)

## node vertex links
model vertices are explicitly defined via relationships to model nodes. 
Node vertex links describe this relationship between a single vertex and a single node.

A single vertex can be linked to 1 or 2 nodes. A given link for a `vertex v` and `node n` contains a vector in the basis of `n` that describes the position, relative to the basis of `n`, that `n` "influences" `v` to. This link also contains a weight `float w` between `0` and `1` that is `n`'s "influence" on `v`

When a vertex is only linked to a single node, the node vertex link will have a weight of `1`, and the link's vector will directly translate to the vertex's position

```
vertex v = TranslatePointToStandard(n.b, link.vector)
```

When a vertex is linked to two nodes, the vertex's position is calculated via the weighted sum of the translated-to-standard link vectors

```
vertex v =
link1.weight * TranslatePointToStandard(link1.node.b, link1.vector)
+ link2.weight * TranslatePointToStandard(link2.node.b, link2.vector)
```

When nodes move, then vertices they are linked to will also move, allowing efficient model deformation and animation

> By default, vertices are linked only to the **zero node**, meaning the links that define them contain vectors in **model space**

## faces
faces are what is actually visible when a model is rendered. These are simply triangles that reference model vertices as triangle vertices. They additionally contain some attributes for color and lighting

```
face = {
    list[index] vertices
    vec_float4 color
    uint32_t normal_reversed
    vec_float3 lighting_offset
    float shading_multiplier
}
```

the **color** is a `vec_float4` representing `(r, g, b, a)` values from `0-1`

the **normal** of a face is a unit vector that, from any point on the face, points outward out of the model. This vector is calculated via the cross product of `<vertices[1], vertices[0]>` and `<vertices[3], vertices[0]>`. If `normal_reversed = true`, we multiply this cross product by `-1`

> the **normal** is mainly used for lighting calculations. For more information on this, and the other face lighting attributes, see **lighting**