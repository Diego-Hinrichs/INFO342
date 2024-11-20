#include <iostream>
#include <chrono>

void prefix_sum_cpu(int* input, int* output, int n) {
    output[0] = input[0];
    for (int i = 1; i < n; ++i) {
        output[i] = output[i - 1] + input[i];
    }
}
