#version 330 core

uniform float uTime;
uniform vec2 uMouse;

in vec2 TexCoord;
out vec4 FragColor;

mat2 rot2d(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * h * k * 0.1666;
}

float sdf_sphere(vec3 p) {
    return length(p) - 1.0;
}

float sdf_box(vec3 p) {
    return length(max(abs(p) - 1.0, 0.0));
}

float sdf_cylinder(vec3 p) {
    return max(length(abs(p.xy)) - 1.0, abs(p.z) - 1.0);
}

float sdf_capsule(vec3 p, float s) {
    p = p.xzy;
    vec3 a = vec3(0.0, -s, 0.0);
    vec3 b = vec3(0.0, +s, 0.0);
    float r = 1.0;
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float sdf(vec3 p) {
    vec3 q;

    q = p;
    q.x -= 1.0;
    q /= 0.05;
    q = q.yzx;
    float axis_x = sdf_capsule(q, 1.0 / 0.05) * 0.05;

    q = p;
    q.y -= 1.0;
    q /= 0.05;
    q = q.zxy;
    float axis_y = sdf_capsule(q, 1.0 / 0.05) * 0.05;

    q = p;
    q.z -= 1.0;
    q /= 0.05;
    q = q.xyz;
    float axis_z = sdf_capsule(q, 1.0 / 0.05) * 0.05;

    float axes;
    axes = axis_x;
    axes = min(axes, axis_y);
    axes = min(axes, axis_z);

    float d;
    d = axes;
    return d;
}

vec3 palette(vec3 p, float t) {
    // return vec3(t);
    return normalize(p);
}

void main(void) {
    vec2 uv = TexCoord - vec2(0.5);
    vec2 mouse = uMouse - vec2(0.5);
    vec3 color = vec3(0.0);
    vec3 ro = vec3(0.0, 0.0, -8.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    float t = 0.0;
    ro.yz *= rot2d(1.0 * -mouse.y);
    rd.yz *= rot2d(1.0 * -mouse.y);
    ro.xz *= rot2d(1.0 * -mouse.x);
    rd.xz *= rot2d(1.0 * -mouse.x);
    vec3 p = ro;
    for (int i = 0; i < 64; i++) {
        p = ro + t * rd;
        float d = sdf(p);
        t += d;
        if (d < 0.001) break;
        if (t > 100.0) break;
    }
    color = palette(p, t * 0.05);
    FragColor = vec4(color, 1.0);
}
