#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include <chrono>

using namespace std;

//*******************************************

// Write down the kernels here
__global__ void memset_int(int *arr,int value,int size){
    if(threadIdx.x<size)
    arr[threadIdx.x]=value;
}

__global__ void checktanks(int *gpu_health_write, int *gpu_num_of_tanks_alive){
    if(gpu_health_write[threadIdx.x]<=0){
        atomicSub(&gpu_num_of_tanks_alive[0],1);
    }
}


__global__ void start_current_round(int *gpu_xcoord, int * gpu_ycoord, int *gpu_score, int *gpu_health_write, int *gpu_health_read, int T, int N, int *gpu_shortest_distance, int round_number){
    int source_tank = blockIdx.x;
    int destination_tank = (source_tank + round_number) % T;
    int current_tank = threadIdx.x;
    long long int source_x = gpu_xcoord[source_tank]; 
    long long int source_y = gpu_ycoord[source_tank];
    long long int destination_x = gpu_xcoord[destination_tank]; 
    long long int destination_y = gpu_ycoord[destination_tank];
    long long int current_x = gpu_xcoord[current_tank];
    long long int current_y = gpu_ycoord[current_tank];
    int direction = 1;
    int distance = -1;
    

    if(destination_tank != source_tank && current_tank != source_tank){
        if(destination_y == source_y){
            direction = destination_x > source_x ? 1 : -1;
        }
        else if(source_y > destination_y){
            direction = -1;
        }
    

        if(gpu_health_read[source_tank]>0 && gpu_health_read[current_tank]>0){
            long long int lhs = (destination_x-source_x) * (current_y-source_y);
            long long int rhs = (current_x-source_x) * (destination_y-source_y);

            if(lhs==rhs){
                if((direction == 1 && (source_y < current_y || (source_y == current_y && source_x < current_x))) || (direction == -1 && (source_y > current_y || (current_y == source_y && source_x > current_x)))){
                    distance = abs(current_y - source_y) + abs(current_x - source_x);   
                    atomicMin(&gpu_shortest_distance[source_tank], distance);
                }
            }
        

        }
    }
    __syncthreads();
    if(gpu_shortest_distance[source_tank] == distance) {
        atomicAdd(&gpu_score[source_tank], 1);
        atomicSub(&gpu_health_write[current_tank], 1);
    }
}


//***********************************************


int main(int argc,char **argv)
{
    // Variable declarations
    int M,N,T,H,*xcoord,*ycoord,*score;
    

    FILE *inputfilepointer;
    
    //File Opening for read
    char *inputfilename = argv[1];
    inputfilepointer    = fopen( inputfilename , "r");

    if ( inputfilepointer == NULL )  {
        printf( "input.txt file failed to open." );
        return 0; 
    }

    fscanf( inputfilepointer, "%d", &M );
    fscanf( inputfilepointer, "%d", &N );
    fscanf( inputfilepointer, "%d", &T ); // T is number of Tanks
    fscanf( inputfilepointer, "%d", &H ); // H is the starting Health point of each Tank
	
    // Allocate memory on CPU
    xcoord=(int*)malloc(T * sizeof (int));  // X coordinate of each tank
    ycoord=(int*)malloc(T * sizeof (int));  // Y coordinate of each tank
    score=(int*)malloc(T * sizeof (int));  // Score of each tank (ensure that at the end you have copied back the score calculations on the GPU back to this allocation)

    // Get the Input of Tank coordinates
    for(int i=0;i<T;i++)
    {
      fscanf( inputfilepointer, "%d", &xcoord[i] );
      fscanf( inputfilepointer, "%d", &ycoord[i] );
    }
		

    auto start = chrono::high_resolution_clock::now();

    //*********************************
    // Your Code begins here (Do not change anything in main() above this comment)
    //********************************

    int *gpu_xcoord;
    int *gpu_ycoord;
    int *gpu_score;
    int *gpu_health_write;
    int *gpu_shortest_distance;
    int *gpu_health_read;
    int *gpu_num_of_tanks_alive;

    int num_of_tanks_alive[1] = {T};

    cudaMalloc(&gpu_xcoord,sizeof(int) * T);
    cudaMalloc(&gpu_ycoord,sizeof(int) * T);
    cudaMalloc(&gpu_score,sizeof(int) * T);
    cudaMalloc(&gpu_shortest_distance, sizeof(int) * T);
    memset_int<<<1,T>>>(gpu_score, 0, T);
    cudaMalloc(&gpu_health_write, sizeof(int) * T);
    cudaMalloc(&gpu_health_read, sizeof(int) * T);
    memset_int<<<1,T>>>(gpu_health_write, H, T);
    memset_int<<<1,T>>>(gpu_health_read, H, T);
    cudaMemcpy(gpu_xcoord, xcoord, sizeof(int) * T, cudaMemcpyHostToDevice);
    cudaMemcpy(gpu_ycoord ,ycoord ,sizeof(int) * T, cudaMemcpyHostToDevice);
    memset_int<<<1,T>>>(gpu_shortest_distance, INT_MAX, T);
    cudaMalloc(&gpu_num_of_tanks_alive, sizeof(int));
    memset_int<<<1,1>>>(gpu_num_of_tanks_alive, T, 1);
    

    for(int round_number = 1; num_of_tanks_alive[0] > 1; round_number++){
        start_current_round<<<T,T>>>(gpu_xcoord, gpu_ycoord, gpu_score, gpu_health_write, gpu_health_read, T, N, gpu_shortest_distance, round_number);
        memset_int<<<1,T>>>(gpu_shortest_distance, INT_MAX, T);
        checktanks<<<1,T>>>(gpu_health_write, gpu_num_of_tanks_alive);
        cudaMemcpy(&num_of_tanks_alive[0], gpu_num_of_tanks_alive, sizeof(int), cudaMemcpyDeviceToHost);
        memset_int<<<1,1>>>(gpu_num_of_tanks_alive, T, 1);
        cudaMemcpy(gpu_health_read,gpu_health_write,sizeof(int) * T, cudaMemcpyDeviceToDevice);
        cudaDeviceSynchronize();
    }

    cudaMemcpy(score, gpu_score, sizeof(int) * T, cudaMemcpyDeviceToHost);
    cudaDeviceSynchronize();


    //*********************************
    // Your Code ends here (Do not change anything in main() below this comment)
    //********************************

    auto end  = chrono::high_resolution_clock::now();

    chrono::duration<double, std::micro> timeTaken = end-start;

    printf("Execution time : %f\n", timeTaken.count());

    // Output
    char *outputfilename = argv[2];
    char *exectimefilename = argv[3]; 
    FILE *outputfilepointer;
    outputfilepointer = fopen(outputfilename,"w");

    for(int i=0;i<T;i++)
    {
        fprintf( outputfilepointer, "%d\n", score[i]);
    }
    fclose(inputfilepointer);
    fclose(outputfilepointer);

    outputfilepointer = fopen(exectimefilename,"w");
    fprintf(outputfilepointer,"%f", timeTaken.count());
    fclose(outputfilepointer);

    free(xcoord);
    free(ycoord);
    free(score);
    cudaDeviceSynchronize();
    return 0;
}