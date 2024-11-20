#include <iostream>
#include <cuda_runtime.h>

#define BSIZE 1024

__global__ void prefix_sum_intra_block(int* d_input, int* d_output, int n) {
    __shared__ int temp[BSIZE];

    int index = threadIdx.x + blockIdx.x * blockDim.x;
    int tid = threadIdx.x;

    // cargar datos en shared memory
    if (index < n) {
        temp[tid] = d_input[index];
    } else {
        temp[tid] = 0;
    }
    __syncthreads();

    //prefix sum en memoria compartida
    for (int offset = 1; offset < blockDim.x; offset *= 2) {
        int temp_val = (tid >= offset) ? temp[tid - offset] : 0;
        __syncthreads();
        if (tid >= offset) {
            temp[tid] += temp_val;
        }
        __syncthreads();
    }

    // escribir resultados en memoria global
    if (index < n) {
        d_output[index] = temp[tid];
    }
}

// calcular las sumas finales de cada bloque
__global__ void block_sums_kernel(int* d_output, int* d_block_sums, int n) {
    int index = threadIdx.x + blockIdx.x * blockDim.x;

    if (index < n && threadIdx.x == blockDim.x - 1) {
        d_block_sums[blockIdx.x] = d_output[index];
    }
}

// ajustar las sumas entre bloques
__global__ void adjust_inter_block(int* d_output, int* d_block_sums, int n) {
    int index = threadIdx.x + blockIdx.x * blockDim.x;

    if (blockIdx.x > 0 && index < n) {
        d_output[index] += d_block_sums[blockIdx.x - 1];
    }
}

void prefix_sum_gpu(int* input, int* output, int n) {
    int threads_per_block = BSIZE;                                      // threads x bloque
    int grid_size = (n + threads_per_block - 1) / threads_per_block;    // bloques necesarios
    int *d_input, *d_output, *d_block_sums;

    cudaMalloc((void**)&d_input, n * sizeof(int));
    cudaMalloc((void**)&d_output, n * sizeof(int));
    cudaMalloc((void**)&d_block_sums, grid_size * sizeof(int));

    cudaMemcpy(d_input, input, n * sizeof(int), cudaMemcpyHostToDevice);

    // prefix sum en cada bloque
    prefix_sum_intra_block<<<grid_size, threads_per_block>>>(d_input, d_output, n);
    cudaDeviceSynchronize();

    // sumas finales de cada bloque
    block_sums_kernel<<<grid_size, threads_per_block>>>(d_output, d_block_sums, n);
    cudaDeviceSynchronize();

    // copiar las sumas de bloques al host para ajuste inter-bloque
    int* h_block_sums = new int[grid_size];
    cudaMemcpy(h_block_sums, d_block_sums, grid_size * sizeof(int), cudaMemcpyDeviceToHost);

    // calcular los ajustes acumulativos de los bloques en el host
    for (int i = 1; i < grid_size; ++i) {
        h_block_sums[i] += h_block_sums[i - 1];
    }

    // copiar los ajustes acumulativos de vuelta a la GPU
    cudaMemcpy(d_block_sums, h_block_sums, grid_size * sizeof(int), cudaMemcpyHostToDevice);
    delete[] h_block_sums;

    // ajustar las sumas inter-bloque
    adjust_inter_block<<<grid_size, threads_per_block>>>(d_output, d_block_sums, n);
    cudaDeviceSynchronize();

    // copiar el resultado final al host
    cudaMemcpy(output, d_output, n * sizeof(int), cudaMemcpyDeviceToHost);

    // liberar memoria
    cudaFree(d_input);
    cudaFree(d_output);
    cudaFree(d_block_sums);
}
