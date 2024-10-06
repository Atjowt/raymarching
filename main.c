#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>
#include <time.h>

#ifdef VERTEX_SHADERS
#define N_VERTEX_SHADERS (sizeof((const char*[])VERTEX_SHADERS) / sizeof(char*))
#else
#define VERTEX_SHADERS {""}
#error "Must provide at least one vertex shader file!"
#endif

#ifdef FRAGMENT_SHADERS
#define N_FRAGMENT_SHADERS (sizeof((const char*[])FRAGMENT_SHADERS) / sizeof(char*))
#else
#define FRAGMENT_SHADERS {""}
#error "Must provide at least one fragment shader file!"
#endif

static const int target_width = 512;
static const int target_height = 512;
static const float target_aspect = (float)target_width / target_height;
static float mouse_x, mouse_y;
static int viewport_x, viewport_y;
static int viewport_width, viewport_height;
static int buffer_width, buffer_height;

static const float vertices[] = {
	-1.0f, +1.0f,
	-1.0f, -1.0f,
	+1.0f, -1.0f,

	-1.0f, +1.0f,
	+1.0f, -1.0f,
	+1.0f, +1.0f,
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
	buffer_width = width;
	buffer_height = height;
	float current_aspect = (float)buffer_width / buffer_height;
	if (current_aspect < target_aspect) {
		viewport_width = buffer_width;
		viewport_height = viewport_width / target_aspect;
	} else {
		viewport_height = buffer_height;
		viewport_width = viewport_height * target_aspect;
	}
	viewport_x = (buffer_width - viewport_width) / 2;
	viewport_y = (buffer_height - viewport_height) / 2;
	glViewport(viewport_x, viewport_y, viewport_width, viewport_height);
}

void recalculate_mouse_pos(GLFWwindow* window, double x, double y) {
	mouse_x = ((x - viewport_x) / viewport_width - 0.5) * 2.0;
	mouse_y = -((y - viewport_y) / viewport_height - 0.5) * 2.0;
}

GLuint compile_shader(GLenum type, int n_files, const char** files) {
	GLuint shader = glCreateShader(type);
	char** sources = malloc(n_files * sizeof(char*));
	for (int i = 0; i < n_files; i++) {
		sources[i] = read_all_text(files[i]);
	}
	glShaderSource(shader, n_files, (const GLchar**)sources, NULL);
	glCompileShader(shader);
	GLint success;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
	if (!success) {
		GLchar info[1024];
		glGetShaderInfoLog(shader, sizeof(info), NULL, info);
		fprintf(stderr, "Error compiling shader: %s\n", info);
	}
	for (int i = 0; i < n_files; i++) {
		free(sources[i]);
	}
	free(sources);
	return shader;
}

GLuint load_shaders(void) {
	GLuint shader = glCreateProgram();
	GLuint vs = compile_shader(GL_VERTEX_SHADER, N_VERTEX_SHADERS, (const char*[])VERTEX_SHADERS);
	GLuint fs = compile_shader(GL_FRAGMENT_SHADER, N_FRAGMENT_SHADERS, (const char*[])FRAGMENT_SHADERS);
	glAttachShader(shader, vs);
	glAttachShader(shader, fs);
	glLinkProgram(shader);
	GLint success;
	glGetProgramiv(shader, GL_LINK_STATUS, &success);
	if (!success) {
		char info[1024];
		glGetProgramInfoLog(shader, sizeof(info), NULL, info);
		fprintf(stderr, "Error linking shaders: %s\n", info);
        }
	glDeleteShader(vs);
	glDeleteShader(fs);
	return shader;
}

int main(void) {

	glfwInit();
	glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE);
	buffer_width = target_width;
	buffer_height = target_height;
	viewport_width = buffer_width;
	viewport_height = buffer_height;
	viewport_x = 0;
	viewport_y = 0;
	GLFWwindow* window = glfwCreateWindow(buffer_width, buffer_height, "Ocean", NULL, NULL);
	glfwSetFramebufferSizeCallback(window, fit_viewport_framebuffer);
	glfwSetCursorPosCallback(window, recalculate_mouse_pos);
	/*glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);*/
	glfwMakeContextCurrent(window);
	gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);

	GLuint VAO, VBO;

	glGenVertexArrays(1, &VAO);
	glGenBuffers(1, &VBO);

	glBindVertexArray(VAO);

	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*)0);
	glEnableVertexAttribArray(0);

	/*glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)(2 * sizeof(float)));*/
	/*glEnableVertexAttribArray(1);*/

	GLuint shader = load_shaders();

	glUseProgram(shader);
	glBindVertexArray(VAO);

	glClearColor(0.0, 0.0, 0.0, 1.0);

	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	struct stat file_stat;
	time_t last_mod_time = 0;
	for (int i = 0; i < N_FRAGMENT_SHADERS; i++) {
		stat((const char*[])FRAGMENT_SHADERS[i], &file_stat);
		if (file_stat.st_mtime >= last_mod_time) {
			last_mod_time = file_stat.st_mtime;
		}
	}
	double last_reload = glfwGetTime();

	while (!glfwWindowShouldClose(window)) {

		if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS) {
			glfwSetWindowShouldClose(window, GLFW_TRUE);
		}

		if (glfwGetKey(window, GLFW_KEY_R) == GLFW_PRESS) {
			last_reload = 0.0;
		}

		if (glfwGetTime() - last_reload >= 0.5) {
			time_t last_modified = 0;
			for (int i = 0; i < N_FRAGMENT_SHADERS; i++) {
				stat((const char*[])FRAGMENT_SHADERS[i], &file_stat);
				if (file_stat.st_mtime >= last_mod_time) {
					last_modified = file_stat.st_mtime;
				}
			}
			if (last_modified > last_mod_time) {
				last_mod_time = last_modified;
				printf("Change detected, reloading shaders...\n");
				glDeleteProgram(shader);
				shader = load_shaders();
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
