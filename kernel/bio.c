// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.


#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"
#define NBUCKET 23
struct {
  struct spinlock lock;
  struct buf buf[NBUF];

  // Linked list of all buffers, through prev/next.
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  struct buf head;
} bcache;

struct spinlock hashLock[NBUCKET];
uint glo_tick = 0;
void
binit(void)
{
  struct buf *b;

  initlock(&bcache.lock, "bcache");

  // Create linked list of buffers
  for(int i=0;i< NBUCKET; i++){
    initlock(hashLock+i,"bache");
  }
  for(int i=0;i<NBUF;i++){
    bcache.buf[i].hashBucket = i%NBUCKET;
    // bcache.buf[i].ticks = getTicks();
    bcache.buf[i].ticks = 0;
  }
  for(b= bcache.buf;b < bcache.buf+NBUF;b++){
    initsleeplock(&b->lock,"buffer");
  }
}
// void
// binit(void)
// {
//   struct buf *b;

//   initlock(&bcache.lock, "bcache");

//   // Create linked list of buffers
//   bcache.head.prev = &bcache.head;
//   bcache.head.next = &bcache.head;
//   for(b = bcache.buf; b < bcache.buf+NBUF; b++){
//     b->next = bcache.head.next;
//     b->prev = &bcache.head;
//     initsleeplock(&b->lock, "buffer");
//     bcache.head.next->prev = b;
//     bcache.head.next = b;
//   }
// }

// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
// static struct buf*
// bget(uint dev, uint blockno)
// {
//   struct buf *b;

//   acquire(&bcache.lock);

//   // Is the block already cached?
//   for(b = bcache.head.next; b != &bcache.head; b = b->next){
//     if(b->dev == dev && b->blockno == blockno){
//       b->refcnt++;
//       release(&bcache.lock);
//       acquiresleep(&b->lock);
//       return b;
//     }
//   }

//   // Not cached.
//   // Recycle the least recently used (LRU) unused buffer.
//   for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
//     if(b->refcnt == 0) {
//       b->dev = dev;
//       b->blockno = blockno;
//       b->valid = 0;
//       b->refcnt = 1;
//       release(&bcache.lock);
//       acquiresleep(&b->lock);
//       return b;
//     }
//   }
//   panic("bget: no buffers");
// }

static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;
  for(int i=0;i<NBUF;i++){
    b= bcache.buf +i;
    if(b->dev == dev &&b->blockno == blockno){
      acquire(&hashLock[b->hashBucket]);
      if(b->dev == dev &&b->blockno == blockno){
        b->refcnt++;
        b-> ticks = glo_tick;
        glo_tick++;
        release(&hashLock[b->hashBucket]);
        acquiresleep(&b->lock);
        return b;
      }
      release(&hashLock[b->hashBucket]);
      break;
    }
  }


  acquire(&bcache.lock);
  for(int i=0;i<NBUF;i++){
    b = bcache.buf +i;
    if(b->dev == dev &&b->blockno ==blockno){
      acquire(&hashLock[b->hashBucket]);
      b->refcnt++;
      b->ticks = glo_tick++;
      release(&hashLock[b->hashBucket]);
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // Not cached.
  // Recycle the least recently used (LRU) unused buffer.
  while(1){
    uint minTime = -1;
    struct buf *evitP = 0;
    for(int i=0;i<NBUF;i++){
      b = bcache.buf +i;
      if(b->refcnt ==0 && minTime > b->ticks){
        evitP = b;
        minTime = b->ticks;
      }
    }
    if(evitP){
      if(evitP->refcnt!=0){
        continue;
      }

      acquire(&hashLock[evitP->hashBucket]);
      evitP->dev = dev;
      evitP->blockno = blockno;
      evitP-> valid = 0;
      evitP-> refcnt = 1;
      evitP -> ticks = glo_tick++;

      release(&hashLock[evitP->hashBucket]);
      release(&bcache.lock);
      acquiresleep(&evitP -> lock);
      return evitP;
    }else{
      panic("bget: no buffers");
    }
  }
  panic("bget: no buffers");
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}

// Release a locked buffer.
// Move to the head of the most-recently-used list.
// void
// brelse(struct buf *b)
// {
//   if(!holdingsleep(&b->lock))
//     panic("brelse");

//   releasesleep(&b->lock);

//   acquire(&bcache.lock);
//   b->refcnt--;
//   if (b->refcnt == 0) {
//     // no one is waiting for it.
//     b->next->prev = b->prev;
//     b->prev->next = b->next;
//     b->next = bcache.head.next;
//     b->prev = &bcache.head;
//     bcache.head.next->prev = b;
//     bcache.head.next = b;
//   }
  
//   release(&bcache.lock);
// }
void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");

  releasesleep(&b->lock);

  acquire(&hashLock[b->hashBucket]);
  b->refcnt --;
  b->ticks = glo_tick++;
  release(&hashLock[b->hashBucket]);
}

// void
// bpin(struct buf *b) {
//   acquire(&bcache.lock);
//   b->refcnt++;
//   release(&bcache.lock);
// }
void
bpin(struct buf *b) {
  acquire(&hashLock[b->hashBucket]);
  b->refcnt++;
  release(&hashLock[b->hashBucket]);
}


// void
// bunpin(struct buf *b) {
//   acquire(&bcache.lock);
//   b->refcnt--;
//   release(&bcache.lock);
// }
void
bunpin(struct buf *b) {
  acquire(&hashLock[b->hashBucket]);
  b->refcnt--;
  release(&hashLock[b->hashBucket]);
}


