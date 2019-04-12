
#version 440

layout(local_size_x=16, local_size_y=16) in;

layout(binding=0) buffer i_buffer_color
{
    vec4 i_col[];
};

layout(binding=1) buffer i_buffer_normal
{
    vec4 i_nor[];
};

layout(binding=2) buffer o_buffer_output
{
    vec4 o_scene[];
};

uniform int u_width;
uniform int u_height;

uniform vec3 u_lightpos;
uniform vec3 u_eye;

uint i_at(uvec2 xy)
{
    return xy.y * u_width + xy.x;;
}

void main()
{
    uvec2 xy = gl_LocalInvocationID.xy + gl_WorkGroupID.xy * 16;
    uint i = i_at(xy);

    vec3 rgb;

    float depth = i_col[i].w;
    vec3 V = normalize(u_eye);
    vec3 L = normalize(u_lightpos);
    vec3 C = i_col[i].xyz;
    vec3 N = i_nor[i].xyz * 2.0 - 1.0;
    vec3 H = normalize(V + L);

    float ndl = dot(L, N);
    ndl = clamp(ndl, 0.0, 1.0);

    float ndh = dot(H, N);
    ndh = pow(ndh, 128.0);
    ndh = clamp(ndh, 0.0, 1.0);

    vec3 diffuse = ndl * C;
    vec3 spec = ndh * vec3(0.85);
    rgb.xyz = diffuse + spec;

    {
        vec2 xy_a = vec2(xy + vec2(+1.0, 0.0));
        vec2 xy_b = vec2(xy + vec2(-1.0, 0.0));
        vec2 xy_c = vec2(xy + vec2(0.0, +1.0));
        vec2 xy_d = vec2(xy + vec2(0.0, -1.0));

        vec3 a = i_nor[i_at(uvec2(xy_a))].xyz;
        vec3 b = i_nor[i_at(uvec2(xy_b))].xyz;
        vec3 c = i_nor[i_at(uvec2(xy_c))].xyz;
        vec3 d = i_nor[i_at(uvec2(xy_d))].xyz;

        float sobel = length(a - b) + length(d - c);
        if (sobel > 0.3)
        {
            rgb.xyz = vec3(0.0, 0.0, 1.0);
        }
    }

    rgb.xyz = clamp(rgb, 0.0, 1.0);
    o_scene[i] = vec4(rgb, 1.0);
}
