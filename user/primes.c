#include "kernel/types.h"
#include "user.h"
#include <stddef.h>
void mapping(int n, int fd[])
{
    close(n);//关闭文件描述符n，令n映射到fd[n]
    dup(fd[n]);
    close(fd[0]);
    close(fd[1]);
}
void primes()
{
    int fd[2];
    pipe(fd);
    int prime;//当前的质数
    int ref = read(0, &prime, 4);
    // printf("\n ref=%d\n",ref);
    if(ref == 0)return;//没有质数了
    printf("prime %d\n", prime);
    int pid = fork();
    if(pid == 0){
        int num;
        mapping(1, fd);//将管道映射到1上
        while(read(0,&num, 4))
        {
            if(num%prime != 0){
                write(1, &num, 4); //被这个除不尽就放到下一个管道中
            }
            
        }
    }
    else {
        wait(NULL);
        mapping(0, fd);//将管道映射到0上
        primes();
    }
}
int main(int argc,char* argv[])
{
    int fd[2];
    pipe(fd);//父进程写入，子进程读取
    int pid = fork();
    // printf("test\n");
    // mapping(1,fd);
    // for(int i = 2;i <= 35; i++)
    // write(1, &i, sizeof(int));
    if(pid == 0)
    {
        mapping(1,fd);
        for(int i = 2;i <= 31; i++)//将所有数字塞入管道
            write(1, &i, sizeof(int));

    }
    else{
        mapping(0, fd);
        primes();
    }
    exit(0);
}
