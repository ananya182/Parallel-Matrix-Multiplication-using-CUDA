#include <bits/stdc++.h>
#include <chrono>

#define ll unsigned long long 

using namespace std;

__global__ void multiply(short *blocks1, short *blocks2, int *bidx2, int *bidy1, int *strow1, int *strow2, int *endrow1, int *endrow2, unsigned int *C, int n, int m)
{
    int bx = blockIdx.x;
    int by = blockIdx.y;
    int tx = threadIdx.x;
    int ty = threadIdx.y;

    int row = by * m + ty;
    int col = bx * m + tx;
    ll temp = 0,maxval=4294967295;

    int a=strow1[row],b=endrow1[row];
    int p=strow2[col],q=endrow2[col];

    if(a!=-1 && p!=-1){

    while(a<=b && p<=q){

        if (bidy1[a] == bidx2[p]){

        for (int k = 0; k < m; ++k)
        {
        
            temp += blocks1[m*m*a+m*ty+k] * blocks2[m*m*p+m*k+tx];
        }
        a++;p++;
        
        }

        else if(bidy1[a] < bidx2[p])
        a++;

        else
        p++;
        
    }}
    if(temp>maxval)
    C[row * n + col] = maxval;
    else
    C[row * n + col] =temp;

}

int main(int argc, char **argv)
{
    string infile1 = argv[1];
    string infile2 = argv[2];
    string outfile = argv[3];

    ifstream f1(infile1, ios::binary);
    ifstream f2(infile2, ios::binary);

    int n1, m1, k1, n2, m2, k2, i, j;
    short x;

    f1.read((char *)(&n1), 4);
    f1.read((char *)(&m1), 4);
    f1.read((char *)(&k1), 4);

    vector<short>blocks1,blocks2;
    vector<int>blockidx,blockidy,row_wise_startindex(n1,-1),row_wise_endindex(n1,-1),blockidx2,blockidy2,row_wise_startindex2(n1,-1),row_wise_endindex2(n1,-1);

    short *v1;

    v1 = (short *)malloc(n1 * n1 * sizeof(short));

    for (int p = 0; p < n1 * n1; p++)
    {
        v1[p] = -1;
    }

    for (int p = 0; p < k1; p++)
    {
        f1.read((char *)(&i), 4);
        f1.read((char *)(&j), 4);

        for (int q = 0; q < m1 * m1; q++)
        {
            f1.read((char *)(&x), 2);
            v1[n1 * (i * m1 + q / m1) + j * m1 + q % m1] = x;
        }
    }

    for(int i=0;i<n1/m1;i++){
        for(int j=0;j<n1/m1;j++){
            if(v1[n1 *i * m1 + j * m1]==-1)
            continue;
            else{
            blockidx.push_back(i);
            blockidy.push_back(j);

            }

            for(int q=0;q<m1*m1;q++){
            blocks1.push_back(v1[n1 * (i * m1 + q / m1) + j * m1 + q % m1]);
        }
    }}
    
    int startrow=blockidx[0]*m1,endrow=startrow+m1-1,cur=blockidx[0];

    for(int i=startrow;i<=endrow;i++){
        row_wise_startindex[i]=0;

    }

    for(int i=0;i<blockidx.size();i++){
        if(blockidx[i]!=cur){
        for(int j=startrow;j<=endrow;j++){
        row_wise_endindex[j]=i-1;
    }
    cur=blockidx[i];
    startrow=cur*m1;
    endrow=startrow+m1-1;
    for(int j=startrow;j<=endrow;j++){
        row_wise_startindex[j]=i;
    }}}
        
    for(int j=startrow;j<=endrow;j++){
        row_wise_endindex[j]=blockidx.size()-1;
    }

    f2.read((char *)(&n2), 4);
    f2.read((char *)(&m2), 4);
    f2.read((char *)(&k2), 4);

    for (int p = 0; p < n1 * n1; p++)
    {
        v1[p] = -1;
    }

   for (int p = 0; p < k2; p++)
    {
        f2.read((char *)(&i), 4);
        f2.read((char *)(&j), 4);

        for (int q = 0; q < m1 * m1; q++)
        {
            f2.read((char *)(&x), 2);
            v1[n1 * (i * m1 + q / m1) + j * m1 + q % m1] = x;
        }
    }

    for(int j=0;j<n1/m1;j++){
        for(int i=0;i<n1/m1;i++){
            if(v1[n1 *i * m1 + j * m1]==-1)
            continue;
            else{
            blockidx2.push_back(i);
            blockidy2.push_back(j);

            }

            for(int q=0;q<m1*m1;q++){
            blocks2.push_back(v1[n1 * (i * m1 + q / m1) + j * m1 + q % m1]);
        }
    }}
    
    startrow=blockidy2[0]*m1,endrow=startrow+m1-1,cur=blockidy2[0];

    for(int i=startrow;i<=endrow;i++){
        row_wise_startindex2[i]=0;

    }

    for(int i=0;i<blockidx2.size();i++){
        if(blockidy2[i]!=cur){
        for(int j=startrow;j<=endrow;j++){
        row_wise_endindex2[j]=i-1;
    }
    cur=blockidy2[i];
    startrow=cur*m1;
    endrow=startrow+m1-1;
    for(int j=startrow;j<=endrow;j++){
        row_wise_startindex2[j]=i;
    }}}
        
    for(int j=startrow;j<=endrow;j++){
        row_wise_endindex2[j]=blockidx2.size()-1;
    }

    short *deviceb1,*deviceb2;
    int *bidy1,*bidx2,*strow1,*endrow1,*strow2,*endrow2;
    unsigned int *output, *deviceoutput;

    cudaMalloc((void **)&deviceb1, blocks1.size() * sizeof(short));
    cudaMalloc((void **)&deviceb2, blocks2.size() * sizeof(short));
    cudaMalloc((void **)&bidx2, blockidx2.size() * sizeof(int));
    cudaMalloc((void **)&bidy1, blockidy.size() * sizeof(int));
    cudaMalloc((void **)&strow1, row_wise_startindex.size() * sizeof(int));
    cudaMalloc((void **)&strow2, row_wise_startindex2.size() * sizeof(int));
    cudaMalloc((void **)&endrow1, row_wise_endindex.size() * sizeof(int));
    cudaMalloc((void **)&endrow2, row_wise_endindex2.size() * sizeof(int));

    cudaMemcpy(deviceb1, blocks1.data(), blocks1.size() * sizeof(short), cudaMemcpyHostToDevice);
    cudaMemcpy(deviceb2, blocks2.data(), blocks2.size() * sizeof(short), cudaMemcpyHostToDevice);
    cudaMemcpy(bidx2, blockidx2.data(), blockidx2.size() * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(bidy1, blockidy.data(), blockidy.size() * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(strow1, row_wise_startindex.data(), row_wise_startindex.size() * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(strow2, row_wise_startindex2.data(), row_wise_startindex2.size() * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(endrow1, row_wise_endindex.data(), row_wise_endindex.size() * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(endrow2, row_wise_endindex2.data(), row_wise_endindex2.size() * sizeof(int), cudaMemcpyHostToDevice);

    dim3 DimGrid(n1 / m1 , n1 / m1 , 1);
    dim3 DimBlock(m1, m1, 1);

    cudaMalloc((void **)&deviceoutput, n2 * n2 * sizeof(unsigned int));
    multiply<<<DimGrid, DimBlock>>>(deviceb1, deviceb2, bidx2,bidy1,strow1,strow2,endrow1,endrow2, deviceoutput, n1, m1);
    cudaDeviceSynchronize();

    output = (unsigned int *)malloc(n1 * n1 * sizeof(unsigned int));
    cudaMemcpy(output, deviceoutput, n1 * n1 * sizeof(unsigned int), cudaMemcpyDeviceToHost);

    cudaFree(deviceb1);cudaFree(deviceb2);cudaFree(bidx2);cudaFree(bidy1);
    cudaFree(strow1);cudaFree(strow2);cudaFree(endrow1);cudaFree(endrow2);
    cudaFree(deviceoutput);
   
    ofstream out (outfile, ios_base::binary);
    vector<pair<int,int>>blocks;

    out.write((char *)(&n1), 4);
    out.write((char *)(&m1), 4);

    for(int i=0;i<n1/m1;i++){
        for(int j=0;j<n1/m1;j++){
            for(int q=0;q<m1*m1;q++){
            if(output[n2 * (i * m2 + q / m2) + j * m2 + q % m2] != 0){
            blocks.push_back({i,j});
            break;}
        }
    }}

    int k=blocks.size();
    out.write((char *)(&k), 4);

    for(int i=0;i<blocks.size();i++){
        out.write((char *)(&blocks[i].first), 4);
        out.write((char *)(&blocks[i].second), 4);

        for(int j=0;j<m1*m1;j++){
            out.write((char *)(&output[n1 * (blocks[i].first * m1 + j / m1) + blocks[i].second * m1 + j % m1]), 4);
        }
    }

    free(output);
}

   

  

  
   





    



