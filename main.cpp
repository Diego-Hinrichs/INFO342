#include <iostream>
#include <cstdlib>
#include <chrono> // Para medir el tiempo

void prefix_sum_cpu(int* input, int* output, int n);
void prefix_sum_gpu(int* input, int* output, int n);

void generate_array(int* array, int n) {
    for (int i = 0; i < n; ++i) {
        array[i] = i;
    }
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <cpu|gpu> <array_size>" << std::endl;
        return 1;
    }

    std::string mode = argv[1];
    int n = std::atoi(argv[2]);

    if (n <= 0) {
        std::cerr << "Array size must be a positive integer." << std::endl;
        return 1;
    }

    int* input = new int[n];
    int* output = new int[n];

    generate_array(input, n);

    auto start_time = std::chrono::high_resolution_clock::now();

    if (mode == "cpu") {
        prefix_sum_cpu(input, output, n);
    } else if (mode == "gpu") {
        prefix_sum_gpu(input, output, n);
    } else {
        std::cerr << "Invalid mode. Use 'cpu' or 'gpu'." << std::endl;
        delete[] input;
        delete[] output;
        return 1;
    }

    auto end_time = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed_time = end_time - start_time;

    std::cout << "Array size (bytes): " << n * sizeof(int) << " bytes" << std::endl;
    std::cout << "Execution time: " << elapsed_time.count() << " seconds" << std::endl;
    std::cout << "Last value of prefix_sum: " << output[n - 1] << std::endl;

    delete[] input;
    delete[] output;
    return 0;
}
