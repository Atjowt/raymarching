#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>
#include <time.h>

static float mouse_x, mouse_y;
static int viewport_x, viewport_y;
static int viewport_size;

static const float vertices[] = {
	// positions    // texture coords
	-1.0f, +1.0f,   0.0f, 1.0f, // Top-left
	-1.0f, -1.0f,   0.0f, 0.0f, // Bottom-left
	+1.0f, -1.0f,   1.0f, 0.0f, // Bottom-right

	-1.0f, +1.0f,   0.0f, 1.0f, // Top-left
	+1.0f, -1.0f,   1.0f, 0.0f, // Bottom-right
	+1.0f, +1.0f,   1.0f, 1.0f  // Top-right
};

char* read_all_text(const char* filename) {
	FILE* file = fopen(filename, "r");
	long pos = ftell(file);
	fseek(file, 0, SEEK_END);
	long size = ftell(file);
	fseek(file, pos, SEEK_SET);
	char* text = malloc((size + 1) * sizeof(char));
	fread(text, sizeof(char), size, file);
	text[size] = '\0';
	fclose(file);
	return text;
}

void fit_viewport_framebuffer(GLFWwindow* window, int width, int height) {
	viewport_size = width < height ? width : height;
	viewport_x = (width - viewport_size) / 2;
	viewport_y = (height - viewport_size) / 2;
	glViewport(viewport_x, viewport_y, viewport_size, viewport_size);
}

void recalculate_mouse_pos(GLFWwindow* window, double x, double y) {
	mouse_x = (x - viewport_x) / viewport_size;
	mouse_y = 1.0 - (y - viewport_y) / viewport_size;
}

GLuint load_shaders(const char* vs_path, const char* fs_path) {

	GLint success;
	GLchar info[1024];

	char* vs_src = read_all_text(vs_path);
	GLuint vs = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(vs, 1, (const GLchar*[]) { vs_src }, NULL);
	glCompileShader(vs);
	glGetShaderiv(vs, GL_COMPILE_STATUS, &success);
	if (!success) {
		glGetShaderInfoLog(vs, sizeof(info), NULL, info);
		fprintf(stderr, "Vertex shader compilation error: %s\n", info);
	}

	char* fs_src = read_all_text(fs_path);
	GLuint fs = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(fs, 1, (const GLchar*[]) { fs_src }, NULL);
	glCompileShader(fs);
        glGetShaderiv(fs, GL_COMPILE_STATUS, &success);
	if (!success) {
		glGetShaderInfoLog(fs, sizeof(info), NULL, info);
		fprintf(stderr, "Fragment shader compilation error: %s\n", info);
	}

	GLuint shader = glCreateProgram();
	glAttachShader(shader, vs);
	glAttachShader(shader, fs);
	glLinkProgram(shader);
	glGetProgramiv(shader, GL_LINK_STATUS, &success);
	if (!success) {
		glGetProgramInfoLog(shader, sizeof(info), NULL, info);
		fprintf(stderr, "Shader program linking error: %s\n", info);
        }

	glDeleteShader(vs);
	glDeleteShader(fs);

	free(vs_src);
	free(fs_src);

	return shader;
}

int main(void) {

	glfwInit();
	glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE);
	viewport_size = 512;
	viewport_x = 0;
	viewport_y = 0;
	GLFWwindow* window = glfwCreateWindow(viewport_size, viewport_size, "Raymarching", NULL, NULL);
	glfwSetFramebufferSizeCallback(window, fit_viewport_framebuffer);
	glfwSetCursorPosCallback(window, recalculate_mouse_pos);
	glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
	glfwMakeContextCurrent(window);
	gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);

	GLuint VAO, VBO;

	glGenVertexArrays(1, &VAO);
	glGenBuffers(1, &VBO);

	glBindVertexArray(VAO);

	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)0);
	glEnableVertexAttribArray(0);

	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)(2 * sizeof(float)));
	glEnableVertexAttribArray(1);

	const char* vs_path = "vert.glsl";
	const char* fs_path = "frag.glsl";
	GLuint shader = load_shaders(vs_path, fs_path);

	glUseProgram(shader);
	glBindVertexArray(VAO);

	glClearColor(0.0, 0.0, 0.0, 1.0);

	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	double last_reload = glfwGetTime();
	struct stat file_stat;
	stat(fs_path, &file_stat);
	time_t last_mod_time = file_stat.st_mtime;

	while (!glfwWindowShouldClose(window)) {

		if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS) {
			glfwSetWindowShouldClose(window, GLFW_TRUE);
		}

		if (glfwGetKey(window, GLFW_KEY_R) == GLFW_PRESS) {
			last_reload = 0.0;
		}

		if (glfwGetTime() - last_reload >= 0.5) {
			stat(fs_path, &file_stat);
			int fs_file_changed = file_stat.st_mtime != last_mod_time;
			if (fs_file_changed) {
				last_mod_time = file_stat.st_mtime;
				printf("Change detected, reloading shaders...\n");
				glDeleteProgram(shader);
				shader = load_shaders(vs_path, fs_path);
				glUseProgram(shader);
				glfwSetTime(0.0);
			}
		}

		float time = glfwGetTime();
		glUniform2f(glGetUniformLocation(shader, "uMouse"), mouse_x, mouse_y);
		glUniform1f(glGetUniformLocation(shader, "uTime"), time);

		glClear(GL_COLOR_BUFFER_BIT);
		glDrawArrays(GL_TRIANGLES, 0, 6);
		glfwPollEvents();
		glfwSwapBuffers(window);
	}

	return 0;
}
