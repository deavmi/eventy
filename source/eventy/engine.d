module eventy.engine;

import eventy.queues : Queue;
import eventy.signal : Signal;
import eventy.event : Event;

import std.container.dlist;
import core.sync.mutex : Mutex;

/**
* Engine
*
* An instance of this represents an engine that
* can, at any time, handle the delivery of new
* events, trigger the correct signal handlers
* for the respective events, remove signal
* handlers, add signal handlers, among many
* other things
*/
public final class Engine
{
    /* TODO: Or use a queue data structure */
    private DList!(Queue) queues;
    private Mutex queueLock;

    /* TODO: Or use a queue data structure */
    private DList!(Signal) handlers;
    private Mutex handlerLock;

    this()
    {
        queueLock = new Mutex();
        handlerLock = new Mutex();
    }

    /**
    * Event loop
    */
    public void run()
    {
        while(true)
        {
            /* TODO: Implement me */

            /* TODO: Add yield to stop mutex starvation on a single thread */
        }
    }

    /**
    * push(Event e)
    *
    * Provided an Event, `e`, this will enqueue the event
    * to 
    */
    public void push(Event e)
    {
        Queue matchedQueue = findQueue(e.id);

        if(matchedQueue)
        {
            /* Append to the queue */
            matchedQueue.add(e);
        }
    }

    public Queue findQueue(ulong id)
    {
        /* Lock the queue collection */
        queueLock.lock();

        /* Find the matching queue */
        Queue matchedQueue;
        foreach(Queue queue; queues)
        {
            if(queue.id == id)
            {
                matchedQueue = queue;
                break;
            }
        }

        /* Unlock the queue collection */
        queueLock.unlock();

        return matchedQueue;
    }

    public ulong[] getTypes()
    {
        /* TODO: Implement me */
        return null;
    }
}