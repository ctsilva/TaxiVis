#version 150 core

in vec3 tex;
in float progress;
out vec4 fragColor;

void main(void)
{
  if (tex.x>1 || tex.x<0) discard;
  float alpha = 1-sqrt(tex.y*tex.y+tex.z*tex.z);
  vec4 srcColor = vec4(0.1, 0.3, 0.5, alpha);
  vec4 dstColor = vec4(1.0, 0.2, 0.1, alpha);
  fragColor = mix(srcColor, dstColor, progress);
}
