#version 150 core

uniform int  nVert;
uniform int  zoom;
uniform vec2 center;
uniform vec2 scale;

in vec4 pos;

void main(void)
{
  gl_Position = (gl_VertexID<nVert) ?
    vec4((pos.xy-center)/scale, pos.zw) : pos;
}
