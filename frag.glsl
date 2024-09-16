#version 330 core

uniform float uTime;
uniform vec2 uMouse;

in vec2 TexCoord;
out vec4 FragColor;

mat2 rotate2D(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * h * k * 0.1667;
}

float sdSphere(vec3 p) {
    return length(p) - 1.0;
}

float sdBox(vec3 p) {
    return length(max(abs(p) - 1.0, 0.0));
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float repeat(float p, float s) {
    return mod(p, s) - 0.5 * s;
}

vec3 repeat(vec3 p, vec3 s) {
    return mod(p, s) - 0.5 * s;
}

float map(vec3 p) {
    float spacing = 8.0;
    float speed = 0.5;
    float goop = 4.0;
    float radius = 1.0;

    vec3 q;

    q = p;
    float s = 1.0 + 0.01 * sin(2.5 * (uTime + 0.5 * (q.x + q.z)));
    q /= s;
    float torus = sdTorus(q, vec2(2.0, 1.0)) * s;

    q = p;
    q.y -= spacing * fract(speed * uTime);
    q.y = repeat(q.y, spacing);
    s = 1.0 + 0.1 * sin(4.0 * (uTime + 0.333 * (q.x + q.y + q.z)));
    q /= s;
    float sphere = sdSphere(q / radius) * radius * s;

    return smin(sphere, torus, goop);
}

vec3 map_normal(vec3 p) {
    const float h = 0.001;
    vec3 d = vec3(
            map(vec3(p.x + h, p.y, p.z)) - map(vec3(p.x - h, p.y, p.z)),
            map(vec3(p.x, p.y + h, p.z)) - map(vec3(p.x, p.y - h, p.z)),
            map(vec3(p.x, p.y, p.z + h)) - map(vec3(p.x, p.y, p.z - h))
        );
    return normalize(d);
}

const vec3 lightDir = normalize(vec3(-1.0, -1.0, 1.0));
const vec3 camPos = vec3(0.0, 0.0, -10.0);

const float ambient = 0.05;

vec4 map_color(vec3 p, vec3 rd) {
    vec3 base = 0.5 + 0.5 * vec3(sin(uTime), cos(uTime), 1.0);
    float glossy = 128.0;

    vec3 normal = map_normal(p);

    vec3 reflection = reflect(rd, normal);

    float diffuse = max(ambient, -dot(normal, lightDir));
    float specular = pow(max(0.0, -dot(reflection, lightDir)), glossy);
    vec3 color = mix(base * diffuse, vec3(1.0, 1.0, 1.0), specular);
    return vec4(color, 1.0);
}

const int maxSteps = 256;
const float maxDist = 100.0;
const float minDist = 0.001;

vec4 march(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < maxSteps; i++) {
        if (t > maxDist) break;
        vec3 p = ro + t * rd;
        float d = map(p);
        if (d < minDist) {
            return map_color(p, rd);
        }
        t += d;
    }
    return vec4(vec3(ambient), 1.0);
}

void main(void) {
    vec2 uv = TexCoord - 0.5;
    // vec2 uv = fract(4 * TexCoord) - 0.5;
    vec2 mouse = uMouse - 0.5;

    vec3 ro = camPos;
    vec3 rd = normalize(vec3(uv, 1.0));
    ro.yz *= rotate2D(1.0 * -mouse.y);
    ro.xz *= rotate2D(1.0 * -mouse.x);
    rd.yz *= rotate2D(1.0 * -mouse.y);
    rd.xz *= rotate2D(1.0 * -mouse.x);
    vec4 color = march(ro, rd);
    // color.xyz = pow(color.xyz, vec3(1.0 / 2.2)); // Linear -> Gamma
    FragColor = color;
}
