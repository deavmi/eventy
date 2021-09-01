module eventy.queues;

import eventy.event : Event;
import core.sync.mutex : Mutex;
import std.container.dlist;
import std.range;

/**
* Queue
*
* Represents a queue with a given ID that can
* have Event-s enqueued to it
*/
public final class Queue
{
    public ulong id;
    /* TODO: Add queue of Event's here */

    private DList!(Event) queue;
    private Mutex queueLock;


    this(ulong id)
    {
        this.id = id;
        queueLock = new Mutex();
    }

    public DList!(Event).Range getKak()
    {
        return queue[];
    }

    public void add(Event e)
    {
        /* Lock the queue */
        queueLock.lock();

        queue.insert(e);

        /* Unlock the queue */
        queueLock.unlock();
    }

    public bool hasEvents()
    {
        bool has;

        /* Lock the queue */
        queueLock.lock();

        has = !(queue[]).empty();

        /* Unlock the queue */
        queueLock.unlock();

        return has;
    }

    public Event popEvent()
    {
        Event poppedEvent;

        /* Lock the queue */
        queueLock.lock();
        
        poppedEvent = (queue[]).front();
        queue.removeFront();

        /* Unlock the queue */
        queueLock.unlock();

        return poppedEvent;
    }
}