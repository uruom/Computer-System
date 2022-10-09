#include "kernel/types.h"
#include "user.h"
#include <stddef.h>
void mapping(int n, int fd[])
{
    close(n);//�ر��ļ�������n����nӳ�䵽fd[n]
    dup(fd[n]);
    close(fd[0]);
    close(fd[1]);
}
void primes()
{
    int fd[2];
    pipe(fd);
    int prime;//��ǰ������
    int ref = read(0, &prime, 4);
    // printf("\n ref=%d\n",ref);
    if(ref == 0)return;//û��������
    printf("prime %d\n", prime);
    int pid = fork();
    if(pid == 0){
        int num;
        mapping(1, fd);//���ܵ�ӳ�䵽1��
        while(read(0,&num, 4))
        {
            if(num%prime != 0){
                write(1, &num, 4); //������������ͷŵ���һ���ܵ���
            }
            
        }
    }
    else {
        wait(NULL);
        mapping(0, fd);//���ܵ�ӳ�䵽0��
        primes();
    }
}
int main(int argc,char* argv[])
{
    int fd[2];
    pipe(fd);//������д�룬�ӽ��̶�ȡ
    int pid = fork();
    // printf("test\n");
    // mapping(1,fd);
    // for(int i = 2;i <= 35; i++)
    // write(1, &i, sizeof(int));
    if(pid == 0)
    {
        mapping(1,fd);
        for(int i = 2;i <= 31; i++)//��������������ܵ�
            write(1, &i, sizeof(int));

    }
    else{
        mapping(0, fd);
        primes();
    }
    exit(0);
}
