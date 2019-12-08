#include <iostream>
#include <math.h>
#include<stdio.h>
#include <algorithm>

#define BLOCK_SIZE 16
//int const Nx = 30, Nz = 20;

__global__
void laplacian_GPU (int ordem, int Nz, int Nx,int dz, int dx, float *P, float *Lapla)
{
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int colStride = blockDim.x * gridDim.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int rowStride = blockDim.y * gridDim.y;

    int in_n = ordem / 2;
    int lim_nx = Nx - ordem / 2;
    int lim_nz = Nz - ordem / 2;

    float Pxx,Pzz;

//    printf("in_n = %d",in_n);
    printf("lim_nx = %d",lim_nx);
    for (int i = col; i < lim_nz && i >= in_n; i += colStride){
        for (int j = row; j < lim_nx && j >= in_n; j += rowStride){
            Pzz = P[(i+1) * Nx + j] + P[(i-1) * Nx + j] - P[i * Nx + j] * 2.0;
            Pxx = P[i * Nx + j+1] + P[i * Nx + j-1] - P[i * Nx + j] * 2.0;
            Lapla[i * Nx + j] = Pxx/(dx*dx) + Pzz/(dz*dz);
            printf("Pxx %.3f, Pzz %.3f,i %d, j %d\n",Pxx,Pzz,i,j);
        }
    }
}

void laplacian(int Nx,int Nz,float dx,float dz)
{
    float **P = new float*[Nx];
    P[0] = new float[Nz * Nx];
    for (int i = 1; i < Nz; ++i)
        P[i] = P[i-1] + Nx;

    float **Lapla = new float*[Nx];
    Lapla[0] = new float[Nz * Nx];
    for (int i = 1; i < Nz; ++i)
        Lapla[i] = Lapla[i-1] + Nx;
    float *dP; cudaMalloc((void **) &dP, sizeof(float) * Nz * Nx);
    float *dLapla; cudaMalloc((void **) &dLapla, sizeof(float) * Nz * Nx);

    for (int i = 0; i < Nz; i++){
        for (int j = 0; j < Nx; j++){
            P[i][j] = i*j + i*i*i;
        };
    };

    cudaMemcpy(dP, P[0],sizeof(float) * Nz * Nx, cudaMemcpyHostToDevice);

    dim3 dimBlock(BLOCK_SIZE,BLOCK_SIZE);
    int Gridx = (Nx + dimBlock.x) / dimBlock.x;
    int Gridy = (Nz + dimBlock.y) / dimBlock.y;
    dim3 dimGrid(Gridx,Gridy);

    std::cout<<"dimBlock.x "<<dimBlock.x<<" dimBlock.y "<<dimBlock.y<<std::endl;
    std::cout<<"dimGrid.x "<<dimGrid.x<<" dimGrid.y "<<dimGrid.y<<std::endl;

    int ordem=2;

    laplacian_GPU<<<dimBlock,dimGrid>>>(ordem,Nz,Nx,dz,dx,dP,dLapla);

    cudaError_t err = cudaGetLastError();
    if(err != cudaSuccess)
        std::cout<<"Error: "<<cudaGetErrorString(err)<<std::endl;
    cudaDeviceSynchronize();

    cudaMemcpy(Lapla[0], dLapla,sizeof(float) * Nz * Nx, cudaMemcpyDeviceToHost);

    for(int i=0; i<Nz; i++){
        for(int j=0; j<Nx; j++){
            std::cout << P[i][j] << "  ";
        }
        std::cout << std::endl;
    }

    for(int i=0; i<Nz; i++){
        for(int j=0; j<Nx; j++){
            std::cout << Lapla[i][j] << "  ";
        }
        std::cout << std::endl;
    }

    cudaFree(P);
    cudaFree(Lapla);
}

int main()
{
    int Nx = 10;
    int Nz = 10;
    float dz = 1;
    float dx = 1;

    laplacian(Nx,Nz,dx,dz);
    return 0;
}
