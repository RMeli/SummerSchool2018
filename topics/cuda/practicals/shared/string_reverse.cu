#include <cstdlib>
#include <cstdio>
#include <iostream>

#include "util.hpp"

// TODO : implement a kernel that reverses a string of length n in place
// void reverse_string(char* str, int n)
__global__
void reverse_string_shared(char* str, int n){
    __shared__ char buffer[1024];

    auto idx = threadIdx.x;

    if(idx < n){
        // Load string to buffer
        buffer[idx] = str[idx];

        // Wait for all threads to finish loading
        __syncthreads();

        str[idx] = buffer[n - idx - 1];
    }
}

__global__
void reverse_string_shared_nosync(char* str, int n){
    __shared__ char buffer[1024];
    
    auto idx = threadIdx.x;
    auto idxI = n - threadIdx.x - 1;

    if(idx != idxI && idx < n/2){
        // Load values to swap
        buffer[idx] = str[idx];
        buffer[idxI] = str[idxI];

	// No sync needed (every thread performs an independent swap)

	// Swap
        str[idx] = buffer[idxI];
        str[idxI] = buffer[idx];
    }
}

int main(int argc, char** argv) {
    // check that the user has passed a string to reverse
    if(argc<2) {
        std::cout << "useage : ./string_reverse \"string to reverse\"\n" << std::endl;
        exit(0);
    }

    // determine the length of the string, and copy in to buffer
    auto n = strlen(argv[1]);
    auto string = malloc_managed<char>(n+1);
    std::copy(argv[1], argv[1]+n, string);
    string[n] = 0; // add null terminator

    std::cout << "string to reverse:\n" << string << "\n";

    // TODO : call the string reverse function
    //reverse_string_shared<<<1,n>>>(string, n);    
    //reverse_string_shared<<<1,n>>>(string, n);
    reverse_string_shared_nosync<<<1,n>>>(string, n);

    // print reversed string
    cudaDeviceSynchronize();
    std::cout << "reversed string:\n" << string << "\n";

    // free memory
    cudaFree(string);

    return 0;
}

