// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(int cpuId,void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

// struct {
//   struct spinlock lock;
//   struct run *freelist;
// } kmem;
// change
struct {
  struct spinlock lock;
  struct run *freelist;
} kmem[NCPU];
struct spinlock alllock;
// void
// kinit()
// {
//   initlock(&kmem.lock, "kmem");
//   freerange(end, (void*)PHYSTOP);
// }
void
kinit()
{
  initlock(&alllock, "all");
  uint64 partlen = (PHYSTOP -(uint64)end)>>3;
  for(uint64 i=0;i<NCPU;i++){
    initlock(&kmem[i].lock,"kmem");
    void *st = (void *)PGROUNDUP((uint64)(end)+i*partlen);
    void *ed = (void *)PGROUNDUP((uint64) (end) + (i+1)*partlen);
    freerange(i,st,ed);
  }
  // freerange(end, (void*)PHYSTOP);
}

// void
// freerange(void *pa_start, void *pa_end)
// {
//   char *p;
//   p = (char*)PGROUNDUP((uint64)pa_start);
//   for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
//     kfree(p);
// }
void
freerange(int cpuId,void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    struct run *r = (struct run*)p;
    r->next = kmem[cpuId].freelist;
    kmem[cpuId].freelist = r;
  }
    
}
// add
void steal(int cpuId){
  release(&kmem[cpuId].lock);
  acquire(&alllock);
  for(int i=0;i<NCPU;i++){
    if(i==cpuId)
      continue;
      
    acquire(&kmem[i].lock);
    if(kmem[i].freelist){
      struct run* s = kmem[i].freelist;
      while(s->next){
        s = s->next;
      }
      s->next = kmem[cpuId].freelist;
      kmem[cpuId].freelist = kmem[i].freelist;
      kmem[i].freelist = 0;
    }
    release(&kmem[i].lock);
  }

  acquire(&kmem[cpuId].lock);
  release(&alllock);
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
// void
// kfree(void *pa)
// {
//   struct run *r;

//   if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
//     panic("kfree");

//   // Fill with junk to catch dangling refs.
//   memset(pa, 1, PGSIZE);

//   r = (struct run*)pa;

//   acquire(&kmem.lock);
//   r->next = kmem.freelist;
//   kmem.freelist = r;
//   release(&kmem.lock);
// }
void
kfree(void *pa)
{
  struct run *r;
  int cpuId = cpuid();
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem[cpuId].lock);
  r->next = kmem[cpuId].freelist;
  kmem[cpuId].freelist = r;
  release(&kmem[cpuId].lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
// void *
// kalloc(void)
// {
//   struct run *r;

//   acquire(&kmem.lock);
//   r = kmem.freelist;
//   if(r)
//     kmem.freelist = r->next;
//   release(&kmem.lock);

//   if(r)
//     memset((char*)r, 5, PGSIZE); // fill with junk
//   return (void*)r;
// }
void *
kalloc(void)
{
  // push_off();
  struct run *r;
  int cpuId = cpuid();
  acquire(&kmem[cpuId].lock);
  r = kmem[cpuId].freelist;
  if(!r){
    steal(cpuId);
    r= kmem[cpuId].freelist;
  }
  if(r)
    kmem[cpuId].freelist = r->next;
  release(&kmem[cpuId].lock);
  // pop_off();

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}
