program Clipit
  use rsf

  implicit none
  type (file)                      :: in, out
  type(axa):: az,ax
  integer                          :: n1, n2, i1, i2
  real                             :: clip
  real, dimension (:), allocatable :: trace

  call sf_init()            ! initialize RSF
  in = rsf_input()
  out = rsf_output()

  if (sf_float /= gettype(in)) call sf_error("Need float type")

  call from_par(in,"n1",n1)
  n2 = filesize(in,1)
  call iaxa(in,az,1)
  call iaxa(in,ax,2)

  call from_par("clip",clip) ! command-line parameter

  allocate (trace (n1))

  do i2=1, n2                ! loop over traces
     call rsf_read(in,trace)

     where (trace >  clip) trace =  clip
     where (trace < -clip) trace = -clip

     call rsf_write(out,trace)
  end do

  deallocate (trace)

end program Clipit
