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

vec4 merge(vec4 a, vec4 b) {
    return mix(a, b, float(a.w > b.w));
}

vec4 smerge(vec4 a, vec4 b, float k) {
    return mix(a, b, float(a.w > b.w));
}

float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * h * k * 0.1667;
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

vec4 sdf(vec3 p) {
    vec3 q;

    q = p;
    q.x -= 1.0;
    q /= 0.05;
    q = q.yzx;
    vec4 axis_x = vec4(
            1.0, 0.0, 0.0,
            sdf_capsule(q, 1.0 / 0.05) * 0.05
        );

    q = p;
    q.y -= 1.0;
    q /= 0.05;
    q = q.zxy;
    vec4 axis_y = vec4(
            0.0, 1.0, 0.0,
            sdf_capsule(q, 1.0 / 0.05) * 0.05
        );

    q = p;
    q.z -= 1.0;
    q /= 0.05;
    q = q.xyz;
    vec4 axis_z = vec4(
            0.0, 0.0, 1.0,
            sdf_capsule(q, 1.0 / 0.05) * 0.05
        );

    vec4 unit_axes;
    unit_axes = axis_x;
    unit_axes = merge(unit_axes, axis_y);
    unit_axes = merge(unit_axes, axis_z);

    q = p;
    // q -= vec3(1.0);
    q /= 1.1 + 0.1 * sin(4.0 * uTime);
    vec4 cube = vec4(
            1.0, 1.0, 1.0,
            sdf_box(q)
        );

    vec4 result;
    result = unit_axes;
    result = merge(cube, result);
    return result;
}

vec3 normal_at(vec3 p) {
    float h = 0.001;
    return normalize(vec3(
            sdf(p + vec3(h, 0.0, 0.0)).w - sdf(p - vec3(h, 0.0, 0.0)).w,
            sdf(p + vec3(0.0, h, 0.0)).w - sdf(p - vec3(0.0, h, 0.0)).w,
            sdf(p + vec3(0.0, 0.0, h)).w - sdf(p - vec3(0.0, 0.0, h)).w
        ));
}

vec3 lighting(vec3 normal, vec3 lightDir, vec3 viewDir, vec3 lightColor, vec3 objectColor) {
    // Ambient component
    vec3 ambient = 0.1 * objectColor;

    // Diffuse component
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = diff * lightColor * objectColor;

    // Specular component (Blinn-Phong)
    vec3 halfwayDir = normalize(lightDir + viewDir);
    float spec = pow(max(dot(normal, halfwayDir), 0.0), 32.0); // Shininess = 32
    vec3 specular = lightColor * spec;

    return ambient + diffuse + specular;
}

vec3 raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    const float MAX_DIST = 100.0;
    const float MIN_DIST = 0.001;
    const int MAX_STEPS = 100;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + t * rd;

        vec4 hit = sdf(p);
        float d = hit.w;

        if (d < MIN_DIST) {
            vec3 normal = normal_at(p);
            vec3 lightDir = normalize(vec3(0.5, 0.8, -0.6));
            vec3 viewDir = normalize(-rd);

            vec3 objectColor = hit.xyz;

            // Light color
            vec3 lightColor = vec3(1.0, 1.0, 1.0); // White light

            // Apply Phong lighting model
            vec3 color = lighting(normal, lightDir, viewDir, lightColor, objectColor);
            return color;
        }

        // Increment distance along the ray
        t += d;

        // If we're too far away, break the loop
        if (t > MAX_DIST) break;
    }

    // If no hit, return background color
    return vec3(0.0); // Black background
}

void main(void) {
    vec2 uv = TexCoord - vec2(0.5);
    vec2 mouse = uMouse - vec2(0.5);
    vec3 ro = vec3(0.0, 0.0, -8.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    ro.yz *= rot2d(1.0 * -mouse.y);
    rd.yz *= rot2d(1.0 * -mouse.y);
    ro.xz *= rot2d(1.0 * -mouse.x);
    rd.xz *= rot2d(1.0 * -mouse.x);
    vec3 color = raymarch(ro, rd);
    FragColor = vec4(color, 1.0);
}
