program wave
    use difFinitas
    use rsf
    implicit none
    logical:: verb
    real:: sx,sz,gxbeg,gzbeg,jgx,jsx
    integer:: isx,isz,igxbeg,igzbeg,o1,o2,nr,ijsx,ijgx
    ! Arquivos de entrada
    type(file) :: FcampoVel,Fpulso,Fshots,Fimg,Fsnaps
    type(axa) :: at,az,ax
    ! Parâmetros do modelo
    integer:: nx,nz,nt,nb,ordem,nxTiro,ntTiro,numTiros
    real:: dt,dx,dz
    double precision::start,finish
    ! Imagem
    real,allocatable:: Img(:,:)
    ! Campo de velocidade
    real,allocatable:: campoVel(:,:)
    ! Wavelet
    real,allocatable:: pulso(:)
    real,allocatable:: shots(:,:,:)
    ! Auxiliares
    integer:: i,j,h1A,h2A,k,counter
    integer,allocatable:: fontes(:,:),receptores(:,:,:)


    ! Inicializando o madagascar
    call sf_init()
    ! Variavel de verbose
    call from_par("verb",verb,.false.)

    ! Definindo variáveis que vão conter os arquivos
    Fshots = rsf_input("in")
    FcampoVel = rsf_input("vel")
    Fpulso = rsf_input("wav")
    Fimg = rsf_output("out")

!   ! Retirando do header as informações de geometria
    !   Tiros
    call from_par(Fshots,'n1',ntTiro)
    call from_par(Fshots,'n2',nxTiro)
    call from_par(Fshots,'n3',numTiros)

    !   Campo de velodidade
    call from_par(FcampoVel,"n1",az%n)
    call from_par(FcampoVel,"n2",ax%n)
    call from_par(FcampoVel,"d1",az%d)
    call from_par(FcampoVel,"d2",ax%d)
    call from_par(FcampoVel,"o1",o1)
    call from_par(FcampoVel,"o2",o2)


!   call to_par (Fsnaps,"d1",az%d)
!   call to_par (Fsnaps,"d2",ax%d)
!   call to_par (Fsnaps,"d3",at%d*20)
!   call to_par (Fsnaps,"n1",az%n)
!   call to_par (Fsnaps,"n2",ax%n)
!   call to_par (Fsnaps,"n3",at%n/20-1)
!   call to_par (Fsnaps,"o1",0)
!   call to_par (Fsnaps,"o2",0)
!   call to_par (Fsnaps,"o3",0)

    !   Wavelet
    call iaxa(Fpulso,at,1)

    !   Parâmetros
    call from_par('sxbeg',sx)
    call from_par('sz',sz)
    call from_par('jsx',jsx)
    !call from_par('gxbeg',gxbeg)
    call from_par('gzbeg',gzbeg)
    call from_par('jgx',jgx)
    call from_par('nr',nr)

    isx = int((sx - o2) / ax%d) + 1
    isz = int((sz - o1) / az%d) + 1
    ijsx = int(jsx / ax%d)
    ijgx = int(jgx / ax%d)
    !igxbeg = int((gxbeg - o2)/ ax%d) + 1
    igzbeg = int((gzbeg - o1) / az%d) + 1

    ! Definindo a geometria do output
    call to_par (Fimg,"d1",az%d)
    call to_par (Fimg,"d2",ax%d)
    call to_par (Fimg,"n1",az%n)
    call to_par (Fimg,"n2",ax%n)
    call to_par (Fimg,"n3",1)
    call to_par (Fimg,"o1",0)
    call to_par (Fimg,"o2",0)
    call to_par (Fimg,"o3",0)

    ! Alocando variáveis e lendo
    allocate(shots(ntTiro,nxTiro,numTiros))
    shots=0.
    call rsf_read(Fshots,shots)

    allocate(campoVel(az%n,ax%n))
    campoVel=0.
    call rsf_read(FcampoVel,campoVel)

    allocate(pulso(at%n))
    pulso=0.
    call rsf_read(Fpulso,pulso)

    allocate(Img(az%n,ax%n))

    ! Retirando da variável de geometria as informações de geometria
    dt = at%d
    dz = az%d
    dx = ax%d

    nt = at%n
    nz = az%n
    nx = ax%n

    ! Tamanho de borda
    nb = 0.2 * nx

    ! Ordem do operador laplaciano
    ordem = 8

    ! Posição da fonte
    allocate(fontes(2,numTiros),receptores(2,nr,numTiros))
    fontes(:,1) = [isz,isx]
    receptores(1,:,:) = igzbeg
    receptores(2,1,1) = isx - ijsx
    do j = 2,nr
        receptores(2,j,1) = receptores(2,j-1,1) + ijgx
    end do
    do i = 2,numTiros
        fontes(1,i) = fontes(1,i-1)
        fontes(2,i) = fontes(2,i-1) + ijsx
        receptores(2,1,i) = fontes(2,i-1)
        do j = 2,nr
            receptores(2,j,i) = receptores(2,j-1,i) + ijgx
        end do
    end do

    ! Chamada da subrotina de propagação da onda
    start = omp_get_wtime()
    call rtm (ordem,nz,nx,nt,nb,dx,dz,dt,receptores,shots,pulso,campoVel,fontes,Img)
    finish = omp_get_wtime()

    write(0,*) "Tempo total: ",finish-start

    ! Escrevendo o arquivo de output
    call rsf_write(Fimg,Img)

    ! Saino
    call exit(0)
end program wave

