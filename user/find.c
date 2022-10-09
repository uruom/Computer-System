#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

char* getname(char *path){
    char *p;
    for( p= path+strlen(path);p>=path && *p != '/';p--);
    p++;
    return p;
}
void findpath(char *path,char *file_name){
    int fd;
//     if((fd = open(path, 0)) < 0){
//     fprintf(2, "find: cannot open %s\n", path);
//     return;
//   }
    fd = open(path,0);
    struct stat st;
    fstat(fd,&st);
    char buf[512],*p;
    strcpy(buf,path);
    p = buf+strlen(buf);
    *p++= '/';
    struct dirent de;
    while(read(fd,&de,sizeof(de))==sizeof(de)){
        if (de.inum ==0)
            continue;
        memmove(p,de.name,DIRSIZ);
        p[DIRSIZ] = 0;
        if(stat(buf,&st)<0){
            printf("test?\n");
            continue;
        }
        char *name = getname(buf);
        switch (st.type)
        {
        case T_FILE:
            if(strcmp(name,file_name) == 0){
                printf("%s\n",buf);
            }
            break;
        case T_DIR:
            if(strcmp(name,".")== 0 || strcmp(name, "..")==0){
                continue;
            }
            findpath(buf,file_name);
            break;
        default:
            break;
        }
    }
    close(fd);
}
int main(int argc,char *argv[]){
    findpath(argv[1],argv[2]);
    exit(0);
}