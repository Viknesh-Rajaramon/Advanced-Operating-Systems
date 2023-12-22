/* CSE 536: User-Level Threading Library */
#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"
#include "user/ulthread.h"
#include "kernel/riscv.h"

/* Standard definitions */
#include <stdbool.h>
#include <stddef.h> 

struct ulthread scheduler_thread;
struct ulthread threads[MAXULTHREADS];
enum ulthread_scheduling_algorithm SCHEDULINGALGORITHM;

struct ulthread *current_thread = 0;

int nexttid = 1;
int waitingthreads = 0;

/* Get thread ID*/
int get_current_tid() {
    return current_thread->thread_id;
}

int alloctid() {
    int tid = nexttid;
    nexttid = nexttid + 1;
    return tid;
}

/* Thread initialization */
void ulthread_init(int schedalgo) {
    for (int i = 0; i < MAXULTHREADS; i++) {
        threads[i].state = FREE;
        threads[i].last_schedule_time = 0;
        threads[i].priority = -1;
        threads[i].thread_id = 0;
    }
    
    scheduler_thread.state = RUNNING;
    scheduler_thread.last_schedule_time = 0;
    scheduler_thread.priority = -1;
    scheduler_thread.thread_id = 0;
    
    SCHEDULINGALGORITHM = schedalgo;
}

/* Thread creation */
bool ulthread_create(uint64 start, uint64 stack, uint64 args[], int priority) {
    int index = -1;
    for (index = 0; index < MAXULTHREADS; index++) {
        if (threads[index].state == FREE)
            break;
    }
    
    threads[index].thread_id = alloctid();
    
    threads[index].priority = priority;
    threads[index].stack = stack - PGSIZE;
    threads[index].last_schedule_time = 0;
    threads[index].state = RUNNABLE;
    
    memset(&threads[index].context, 0, sizeof(threads[index].context));
    threads[index].context.ra = start;
    threads[index].context.sp = stack;
    
    // Load the arguments
    threads[index].context.a0 = args[0];
    threads[index].context.a1 = args[1];
    threads[index].context.a2 = args[2];
    threads[index].context.a3 = args[3];
    threads[index].context.a4 = args[4];
    threads[index].context.a5 = args[5];
    
    /* Please add thread-id instead of '0' here. */
    printf("[*] ultcreate(tid: %d, ra: %p, sp: %p)\n", threads[index].thread_id, start, stack);
    waitingthreads += 1;
    return false;
}

int get_next_thread_index() {
    int index = -1;
    int current_thread_index = -1;
    if (SCHEDULINGALGORITHM == FCFS) {
        for (int i = 0; i < MAXULTHREADS; i++) {
            if (threads[i].state != RUNNABLE)
                continue;
                
            if (current_thread != 0 && threads[i].thread_id == current_thread->thread_id) {
                current_thread_index = i;
                continue;
            }
            
            if (index == -1 || threads[i].last_schedule_time < threads[index].last_schedule_time)
                index = i;
        }
    } else if (SCHEDULINGALGORITHM == ROUNDROBIN) {
        for (int i = 0; i < MAXULTHREADS; i++) {
            if (threads[i].state != RUNNABLE)
                continue;
                
            if (current_thread != 0 && threads[i].thread_id == current_thread->thread_id) {
                current_thread_index = i;
                continue;
            }
            
            if (index == -1 || threads[i].last_schedule_time < threads[index].last_schedule_time)
                index = i;
        }
    } else if (SCHEDULINGALGORITHM == PRIORITY) {
        for (int i = 0; i < MAXULTHREADS; i++) {
            if (threads[i].state != RUNNABLE)
                continue;
                
            if (current_thread != 0 && threads[i].thread_id == current_thread->thread_id) {
                current_thread_index = i;
                continue;
            }
                
            if (index == -1 || threads[i].priority > threads[index].priority)
                index = i;
        }
    }
    if (index == -1) // If only one thread is left to be executed (i.e., waitingthreads == 1)
        return current_thread_index;
    
    return index;
}

/* Thread scheduler */
void ulthread_schedule(void) {
    while (waitingthreads > 0) {
        int index = get_next_thread_index();
        
        scheduler_thread.state = RUNNABLE;
        current_thread = &threads[index];
        current_thread->state = RUNNING;
        
        /* Add this statement to denote which thread-id is being scheduled next */
        printf("[*] ultschedule (next tid: %d)\n", current_thread->thread_id);
        
        // Switch betwee thread contexts
        ulthread_context_switch(&scheduler_thread.context, &current_thread->context);
    }
}

/* Yield CPU time to some other thread. */
void ulthread_yield(void) {

    /* Please add thread-id instead of '0' here. */
    printf("[*] ultyield(tid: %d)\n", current_thread->thread_id);
    
    if (SCHEDULINGALGORITHM != FCFS)
    	current_thread->last_schedule_time = ctime();
    
    current_thread->state = RUNNABLE;
    scheduler_thread.state = RUNNING;
    ulthread_context_switch(&current_thread->context, &scheduler_thread.context); // Switch to user-level scheduler thread
}

/* Destroy thread */
void ulthread_destroy(void) {
    current_thread->state = FREE;
    
    scheduler_thread.state = RUNNING;
    printf("[*] ultdestroy(tid: %d)\n", current_thread->thread_id);
    waitingthreads -= 1;
    ulthread_context_switch(&current_thread->context, &scheduler_thread.context); // Switch to user-level scheduler thread
}

