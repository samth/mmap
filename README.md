##### mmap

A binding to the system `mmap()`.

###### Installation

```
$ raco pkg install mmap
```

###### Example

```
$ cat /tmp/x
111111111111111111111111111111111111111111111111111111111111111111111
$ racket
> (require mmap)                                                        
> (define bs (mmap "/tmp/x" #:length 20 #:prot '(PROT_READ PROT_WRITE) #:flags 'MAP_SHARED))
> bs
#"11111111111111111111"
> (bytes-set! bs 0 50)
> bs
#"21111111111111111111"
> 
$ cat /tmp/x
211111111111111111111111111111111111111111111111111111111111111111111
```