
#version 440

#define NEAR 0.5
#define FAR 50.0
#define SURFACE 0.001

layout(local_size_x=16, local_size_y=16) in;

layout(binding=0) buffer o_buffer_color
{
    vec4 o_col[];
};

layout(binding=1) buffer o_buffer_normal
{
    vec4 o_nor[];
};

uniform int u_width;
uniform int u_height;


vec4 rgb;
vec3 normal;

float sphere(vec3 t, float r)
{
    return length(t) - r;
}

float world(vec3 p, bool bcolor=false)
{
    float d = FAR;
    float sph1 = sphere(p, 2.0);

    if (bcolor && sph1 < SURFACE)
    {
        rgb.xyz = vec3(1.0, 0.25, 0.25);
    }

    return sph1;
}

float raymarch(vec3 o, vec3 r)
{
    float t = NEAR;
    vec3 p;
    float d;
    for (int i = 128; i > 0; i--)
    {
        p = o + r * t;
        d = world(p, true);
        if (d < SURFACE) { return t; }
        t += d;
    }
    return t;
}

vec3 normal_at(vec3 p)
{
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        world(p + e.xyy) - world(p - e.xyy),
        world(p + e.yxy) - world(p - e.yxy),
        world(p + e.yyx) - world(p - e.yyx)
    ));
}

void main()
{
    uvec2 xy = gl_LocalInvocationID.xy;
    xy += gl_WorkGroupID.xy * 16;
    uint i = xy.y * u_width + xy.x;

    vec2 uv = vec2(xy) / vec2(u_width, u_height);
    rgb = vec4(0.2, 0.2, 0.2, 1.0);
    normal = vec3(0.0, 0.0, 1.0);

    vec3 o = vec3(0.0, 0.5, -5.0);
    vec3 r = normalize(vec3(uv * 2.0 - 1.0, 1.04));

    float t = raymarch(o, r);
    if (t < FAR)
    {
        vec3 P = o + r * t;
        normal = normal_at(P);
    }
    rgb.w = t / FAR;
    o_col[i] = rgb;

    normal = normal * 0.5 + 0.5;
    o_nor[i] = vec4(normal, 1.0);
}
