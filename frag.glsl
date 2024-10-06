#version 330 core

uniform float uTime;
uniform vec2 uMouse;

in vec2 FragCoord;
out vec4 FragColor;

// defined in "perlin.glsl"
float cnoise(vec2 v);
float cnoise(vec3 v);

mat2 rot2d(float t) {
    float s = sin(t);
    float c = cos(t);
    return mat2(c, -s, s, c);
}

float sdSphere(vec3 v) {
    return length(v) - 1.0;
}

float sdCube(vec3 v) {
    return length(max(abs(v) - 1.0, 0.0));
}

float sdPlane(vec3 v) {
    return dot(v, vec3(0.0, 1.0, 0.0));
}

float sdScene(vec3 v) {
    v.xz *= rot2d(0.2 * uTime);
    float wave = 0.1 * cnoise(2.0 * v.xz + uTime) + 0.02 * cnoise(4.0 * v.xz + uTime) + 0.01 * cnoise(8.0 * v.xz + uTime);
    float water = sdPlane(v - vec3(0.0, wave, 0.0));
    v.yz *= rot2d(0.1 * sin(uTime));
    v.xz *= rot2d(0.1 * uTime);
    float cube = sdCube(v / 0.5 - vec3(0.0, -0.25, 0.0)) * 0.5 - 0.04;
    return min(water, cube);
}

const int MAX_STEPS = 32;
const float MAX_DIST = 32.0;
const float MIN_DIST = 0.001;
vec3 march(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        if (t > MAX_DIST) break;
        vec3 v = ro + t * rd;
        float d = sdScene(v);
        if (d < MIN_DIST) {
            return vec3(0.0, 0.4, 0.6) * 0.1 * t + vec3(1.0, 0.2, 0.6) * pow(float(i) / MAX_STEPS, 4.0);
        }
        t += d;
    }
    return vec3(0.0);
}

void main(void) {
    vec3 ro = vec3(0.0, 0.5, -2.0);
    vec3 rd = normalize(vec3(FragCoord, 1.0));
    vec3 color = march(ro, rd);
    FragColor = vec4(color, 1.0);
}
