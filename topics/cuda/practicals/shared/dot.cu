#include <iostream>

#include <cuda.h>

#include "util.hpp"

// host implementation of dot product
double dot_host(const double *x, const double* y, int n) {
    double sum = 0;
    for(auto i=0; i<n; ++i) {
        sum += x[i]*y[i];
    }
    return sum;
}

// TODO implement dot product kernel
template <int THREADS>
__global__
void dot_gpu_kernel(const double *x, const double* y, double *result, int n) {
    __shared__ double buf[1024];

    auto gid = threadIdx.x + blockIdx.x * blockDim.x;
    auto idx = threadIdx.x;

    buf[idx] = 0;
    if(idx < n){
        buf[idx] = x[gid] * y[gid];
    }

    int m = THREADS / 2;

    while(m){
        __syncthreads(); // wait for other threads
        if(idx < m){
            buf[idx] += buf[idx + m];
        }

        m = m / 2;
    }
    
    if(idx == 0){
        atomicAdd(result, buf[0]);
    }
}

double dot_gpu(const double *x, const double* y, int n) {
    static double* result = malloc_managed<double>(1);
    // TODO call dot product kernel
    *result = 0;
    constexpr auto block_dim = 1024;
    auto grid_dim = (n + block_dim - 1) / block_dim;
    dot_gpu_kernel<block_dim><<<grid_dim,block_dim>>>(x, y, result, n);

    cudaDeviceSynchronize();
    return *result;
}

int main(int argc, char** argv) {
    size_t pow = read_arg(argc, argv, 1, 4);
    size_t n = (1 << pow);

    auto size_in_bytes = n * sizeof(double);

    std::cout << "dot product CUDA of length n = " << n
              << " : " << size_in_bytes*1e-9 << "MB\n";

    auto x_h = malloc_host<double>(n, 2.);
    auto y_h = malloc_host<double>(n);
    for(auto i=0; i<n; ++i) {
        y_h[i] = rand()%10;
    }

    auto x_d = malloc_device<double>(n);
    auto y_d = malloc_device<double>(n);

    // copy initial conditions to device
    copy_to_device<double>(x_h, x_d, n);
    copy_to_device<double>(y_h, y_d, n);

    auto result   = dot_gpu(x_d, y_d, n);
    auto expected = dot_host(x_h, y_h, n);
    printf("expected %f got %f\n", (float)expected, (float)result);

    return 0;
}

