#include <iostream>
#include <math.h>

using namespace std;


void laplacian (int ordem,int Nx,int Nz,float dx,float dz,float **P,float **Lapla)
{
    cout<<P[1][1]<<endl;
}



int main()
{
    int const Nx = 30, Nz = 30;
    float *P[Nz];
    for(int i = 0; i < Nz; i++)
        P[i] = new float[Nx];

    float *Lapla[Nz];
    for(int i = 0; i < Nz; i++)
        Lapla[i] = new float[Nx];

    float soma = 0.0;

    for (int i = 0; i < Nz; i++){
        for (int j = 0; j < Nx; j++){
            P[i][j] = 1;
            soma += P[i][j];
        };
    };

    laplacian(2,Nx,Nz,0.01,0.01,P,Lapla);

    return 0;
}
