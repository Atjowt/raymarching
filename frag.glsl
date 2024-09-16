#version 330 core

uniform float uTime;
uniform vec2 uMouse;

in vec2 TexCoord;
out vec4 FragColor;

//
// Description : Array and textureless GLSL 2D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
//

vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x * 34.0) + 10.0) * x);
}

float snoise(vec2 v)
{
    const vec4 C = vec4(0.211324865405187, // (3.0-sqrt(3.0))/6.0
            0.366025403784439, // 0.5*(sqrt(3.0)-1.0)
            -0.577350269189626, // -1.0 + 2.0 * C.x
            0.024390243902439); // 1.0 / 41.0
    // First corner
    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);

    // Other corners
    vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    // Permutations
    i = mod289(i); // Avoid truncation effects in permutation
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0))
                + i.x + vec3(0.0, i1.x, 1.0));

    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);

    // Compute final noise value at P
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

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

const float PI = 3.1459;
vec2 uvSphere(vec3 p) {
    float u = (atan(p.z, p.x) / (2.0 * PI)) + 0.5;
    float v = (p.y * 0.5) + 0.5;
    return vec2(u, v);
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

vec3 map(vec3 p) {
    vec3 q;
    q = p;
    // q.xy *= rotate2D(uTime);
    float s = 1.0 + 0.04 * snoise(0.5 * (q.xy + q.xz + q.yz) / 3.0);
    q /= s;
    q.y /= 1.1;
    return vec3(uvSphere(q), sdSphere(q));
}

const float H = 0.001;
vec3 get_normal(vec3 p) {
    vec3 grad = vec3(
            map(vec3(p.x + H, p.y, p.z)).z,
            map(vec3(p.x, p.y + H, p.z)).z,
            map(vec3(p.x, p.y, p.z + H)).z
        ) - map(p).z;
    return normalize(grad);
}

const vec3 LIGHT_DIR = normalize(vec3(-1.0, -1.0, 1.0));
const float AMBIENT = 0.08;
const float GLOSSY = 16.0;
const float SPECULAR = 0.5;
vec4 colorize(vec3 p, vec3 q, vec3 rd) {
    float u = q.x;
    float v = q.y;

    vec3 n = get_normal(p);
    n -= 0.012 * snoise(128.0 * vec2(u, v));
    vec3 r = reflect(rd, n);

    float unoised = u + 0.01 * snoise(16.0 * vec2(u, v));
    unoised = unoised + 0.008 * snoise(32.0 * vec2(u, v));
    unoised = unoised + 0.006 * snoise(64.0 * vec2(u, v));

    float stripefac = smoothstep(0.1, 1.0, 0.5 + 0.5 * sin(8.0 * 2.0 * PI * unoised));

    vec3 stripecolor = vec3(0.3, 0.6, 0.1);
    vec3 basegreen = vec3(0.6, 1.0, 0.1);
    vec3 altgreen = vec3(0.3, 0.8, 0.0);
    vec3 albedo;
    albedo = basegreen;
    albedo = mix(albedo, altgreen, snoise(2.0 * vec2(u, v)));
    albedo = mix(albedo, stripecolor, stripefac);
    albedo *= 1.0 + 0.1 * snoise(8.0 * vec2(u, v));
    // vec3 albedo = n;

    float diffuse = max(AMBIENT, -dot(n, LIGHT_DIR));
    float specular = pow(max(0.0, -dot(r, LIGHT_DIR)), GLOSSY);

    vec3 final = mix(albedo * diffuse, vec3(1.0), specular * SPECULAR);

    return vec4(final, 1.0);
}

const int MAX_STEPS = 256;
const float MAX_DIST = 100.0;
const float MIN_DIST = 0.001;
const vec3 SKY_COLOR = vec3(0.05);
vec4 march(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        if (t > MAX_DIST) break;
        vec3 p = ro + t * rd;
        vec3 q = map(p);
        float d = q.z;
        if (d < MIN_DIST) {
            return colorize(p, q, rd);
        }
        t += d;
    }
    return vec4(SKY_COLOR, 1.0);
}

const float CONTRAST = 1.2;
void main(void) {
    vec2 uv = TexCoord - 0.5;
    // vec2 uv = fract(4 * TexCoord) - 0.5;
    vec2 mouse = uMouse - 0.5;

    vec3 ro = vec3(0.0, 0.0, -4.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    ro.yz *= rotate2D(1.0 * -mouse.y);
    ro.xz *= rotate2D(1.0 * -mouse.x);
    rd.yz *= rotate2D(1.0 * -mouse.y);
    rd.xz *= rotate2D(1.0 * -mouse.x);
    vec4 color = march(ro, rd);
    color = pow(color, vec4(CONTRAST));
    // color.xyz = pow(color.xyz, vec3(1.0 / 2.2)); // Linear -> Gamma
    FragColor = color;
}
