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

float sdf_sphere(vec3 p, float r) {
    return length(p) - r;
}

float sdf_box(vec3 p, vec3 s) {
    return length(max(abs(p) - s, 0.0));
}

float sdf(vec3 p) {
    vec3 sphere_pos = vec3(1.5 * sin(uTime), 0.0, 0.0);
    // vec3 box_pos = vec3(-1.5 * sin(uTime), 0.0, 0.0);
    vec3 box_pos = vec3(0.0, 0.0, 0.0);
    vec3 q = p - box_pos;
    q = fract(q) - 0.5;
    q.xy *= rot2d(uTime);
    q.yz *= rot2d(-0.1 * uTime);

    float sphere = sdf_sphere(p - sphere_pos, 1.0);
    float box = sdf_box(q, vec3(0.1));
    float ground = p.y - -0.75;

    float d;
    d = smin(sphere, box, 2.0);
    d = smin(d, ground, 0.5);
    return d;
}

void main(void) {
    vec2 uv = TexCoord - vec2(0.5);
    vec2 mouse = uMouse - vec2(0.5);
    vec3 color = vec3(0.0);
    vec3 ro = vec3(0.0, 0.0, -8.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    float t = 0.0;
    // ro.yz *= rot2d(1.0 * -mouse.y);
    // rd.yz *= rot2d(1.0 * -mouse.y);
    ro.xz *= rot2d(1.0 * -mouse.x);
    rd.xz *= rot2d(1.0 * -mouse.x);
    for (int i = 0; i < 80; i++) {
        vec3 p = ro + t * rd;
        float d = sdf(p);
        t += d;
        if (d < 0.01) break;
        if (t > 100.0) break;
    }
    color = vec3(t * 0.1);
    FragColor = vec4(color, 1.0);
}
