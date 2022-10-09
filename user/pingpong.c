#include "kernel/types.h"
#include "user.h"
int main(int argc,char* argv[])
{
    int fp[2],sp[2];
    pipe(fp);//������д�룬�ӽ��̶�ȡ
    pipe(sp);
    int pid = fork();
    // printf("4: received ping\n");
    // printf("3: received pong\n");
    // int test = 0;
    // if(pid<0)
    // {
    //     printf("error!");
    // }
    if(pid == 0)
    {
        // test++;
        // printf("test:%d\n",test);
        /*�ӽ��� */
        char *buffer = "    ";
        // printf("\n 11\n");
        close(fp[1]); // �ر�д��
        // printf("\n 12\n");
        read(fp[0], buffer, 4);//�����ȴ�
        // printf("\n 13\n");
        
        printf("%d: received %s\n",getpid(),buffer);
        // printf("\n 14\n");
        close(fp[0]); // ��ȡ��ɣ��رն���
        // printf("\n 15\n");
        char *in1 = "pong";
        // printf("\n 16\n");
        close(sp[0]); // �رն���
        // printf("\n 17\n");
        write(sp[1], in1, 4);
        // printf("\n 18\n");
        close(sp[1]); // д����ɣ��ر�д��
        // printf("\n 19\n");

    }
    else{
        /*������*/ 
        char *ou = "ping";
        close(fp[0]); // �رն���
        // printf("\n 1\n");
        write(fp[1], ou, 4);
        // printf("\n 2\n");
        close(fp[1]); // д����ɣ��ر�д��
        // printf("\n 3\n");
        close(sp[1]); // �ر�д��
        // printf("\n 4\n");
        read(sp[0], ou, 4);
        // printf("\n 5\n");
        printf("%d: received %s\n",getpid(),ou);
        // printf("\n 6\n");
        close(sp[0]); // ��ȡ��ɣ��رն���
        // printf("\n 7\n");
    }
    exit(0);
}
