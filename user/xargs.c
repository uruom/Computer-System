#include "kernel/types.h"
#include "user/user.h"
#include "kernel/param.h"

int main(int argc,char* argv[]){
    char *cmd = argv[1];
    char *argvs[MAXARG];
    for(int i=1;i<argc;i++){
        argvs[i-1]=argv[i];
    }
    char buf[1024];
    while(read(0,&buf,sizeof(buf))){
        int length = strlen(buf);
        argvs[argc-1]=&buf[0];
        for(int i=0;i<length;i++){
            if(buf[i] == '\n'){
                if(fork()==0){
                    buf[i]=0;
                    argvs[argc]=0;
                    exec(cmd,argvs);
                }
                wait(0);
                argvs[argc-1]=&buf[i+1];
            }
        }
    }
    exit(0);
}

