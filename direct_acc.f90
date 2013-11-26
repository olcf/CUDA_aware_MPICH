program GPUdirect
    include 'mpif.h'
 
    integer :: direct
    character(len=255) :: env_var
    integer :: rank, size, ierror
    integer,dimension(:),allocatable :: buff
    integer :: i
 
    call getenv("MPICH_RDMA_ENABLED_CUDA", env_var)
    read( env_var, '(i10)' ) direct
    if (direct .NE. 1) then
      print *, 'MPICH_RDMA_ENABLED_CUDA not enabled!'
      call exit(1)
    endif
 
    call MPI_INIT(ierror)
 
    ! Get MPI rank and size
    call MPI_COMM_RANK (MPI_COMM_WORLD, rank, ierror)
    call MPI_COMM_SIZE (MPI_COMM_WORLD, size, ierror)
 
    ! Initialize buffer
    allocate(buff(size))
 
    ! Copy buff to device at start of region and back to host and end of region
    !$acc data copy(rank, buff(1:size))
        ! Inside this region the device data pointer will be used
        !$acc host_data use_device(rank, buff)
            ! Preform all to all using device buffer
            call MPI_ALLGATHER(rank, 1, MPI_INT, buff, 1, MPI_INT, MPI_COMM_WORLD, ierror);
        !$acc end host_data
    !$acc end data
 
    ! Check that buffer is correct
    do i=1,size
        if (buff(i) .NE. i-1) then
            print *, 'Alltoall Failed!'
            call exit(1)
        endif
    enddo
    if (rank .EQ. 0) then
        print *, 'Success!'
    endif
 
    ! Clean up
    deallocate(buff)
    call MPI_FINALIZE(ierror)
end program GPUdirect
