# Variables
CXX = g++
NVCC = nvcc
CXX_FLAGS = -std=c++17 -O2
CUDA_FLAGS = -O2

# Archivos fuente
SRC = main.cpp prefix_sum_cpu.cpp prefix_sum_gpu.cu

# Nombre del ejecutable
TARGET = prog

# Reglas
all: $(TARGET)

$(TARGET):
	$(NVCC) $(CUDA_FLAGS) $(SRC) -o $(TARGET) $(CXX_FLAGS)

clean:
	rm -f $(TARGET)

.PHONY: all clean
