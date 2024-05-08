// util inserted here

// #version 430 core

layout (location = 0) in vec3 pos;

out vec3 pass_color;

void main()
{
    gl_Position = vec4(pos, 1.0);
    pass_color = vec3(1.0, 1.0, 1.0);
}