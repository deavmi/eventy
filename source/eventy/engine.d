module eventy.engine;

import eventy.queues : Queue;
import eventy.signal : Signal, EventHandler;
import eventy.event : Event;

import std.container.dlist;
import core.sync.mutex : Mutex;
import core.thread : Thread;

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

            /* Lock the queue-set */
            queueLock.lock();

            foreach(Queue queue; queues)
            {
                /* If the queue has evenets queued */
                if(queue.hasEvents())
                {
                    /* TODO: Add different dequeuing techniques */

                    /* Pop the first Event */
                    Event headEvent = queue.popEvent();

                    /* Get all signal-handlers for this event type */
                    Signal[] handlersMatched = getSignalsForEvent(headEvent);
                    
                }
            }

            /* Unlock the queue set */
            queueLock.unlock();

            /* TODO: Add yield to stop mutex starvation on a single thread */
        }
    }

    /**
    * Dispatch(Signal[] set, Event e)
    *
    * Creates a new thread per signal and dispatches the event to them
    *
    * TODO: Add ability to dispatch on this thread
    */
    private void dispatch(Signal[] signalSet, Event e)
    {
        foreach(Signal signal; signalSet)
        {
            /* Create a new Thread */
            Thread handlerThread = getThread(signal, e);

            /* Start the thread */
            handlerThread.start();
        }
    }

    private Thread getThread(Signal signal, Event e)
    {
        Thread signalHandlerThread = new class Thread
        {
            this()
            {
                super(&worker);
            }

            public void worker()
            {
                EventHandler handler = signal.getHandler();
                handler(e);
            }
        };

        return signalHandlerThread;
    }

    private Signal[] getSignalsForEvent(Event e)
    {
        /* Matched handlers */
        Signal[] matchedHandlers;

        /* Lock the signal-set */
        handlerLock.lock();

        /* Find all handlers matching */
        foreach(Signal signal; handlers)
        {
            matchedHandlers ~= signal;
        }

        /* Unlock the signal-set */
        handlerLock.unlock();

        return matchedHandlers;
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