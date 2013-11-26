#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
 
int main( int argc, char** argv )
{
    MPI_Init (&argc, &argv);
 
    int direct;
    int rank, size;
    int *restrict buff = NULL;
    size_t bytes;
    int i;
 
    // Ensure that RDMA ENABLED CUDA is set correctly
    direct = getenv("MPICH_RDMA_ENABLED_CUDA")==NULL?0:atoi(getenv ("MPICH_RDMA_ENABLED_CUDA"));
    if(direct != 1){
        printf ("MPICH_RDMA_ENABLED_CUDA not enabled!\n");
        exit (EXIT_FAILURE);
    }
 
    // Get MPI rank and size
    MPI_Comm_rank (MPI_COMM_WORLD, &rank);
    MPI_Comm_size (MPI_COMM_WORLD, &size);
 
    // Initialize buffer
    bytes = size*sizeof(int);
    buff = (int*)malloc(bytes);
 
    // Copy buff to device at start of region and back to host and end of region
    #pragma acc data copy(rank, buff[0:size])
    {
        // Inside this region the device data pointer will be used
        #pragma acc host_data use_device(rank, buff)
        {
            MPI_Allgather(&rank, 1, MPI_INT, buff, 1, MPI_INT, MPI_COMM_WORLD);
        }
    }
 
    // Check that buffer is correct
    for(i=0; i<size; i++){
        if(buff[i] != i) {
            printf ("Alltoall Failed!\n");
            exit (EXIT_FAILURE);
        }
    }
    if(rank==0)
        printf("Success!\n");
 
    // Clean up
    free(buff);
 
    MPI_Finalize();
 
    return 0;
}
