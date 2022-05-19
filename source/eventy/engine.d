module eventy.engine;

import eventy.queues : Queue;
import eventy.signal : Signal;
import eventy.event : Event;

import std.container.dlist;
import core.sync.mutex : Mutex;
import core.thread : Thread, dur, Duration;

import eventy.exceptions;

import std.stdio;

/* TODO: Move elsewhere, this thing thinks it's a delegate in the unit test, idk why */
void runner(Event e)
{
    import std.stdio;

    writeln("Running event", e.id);
}

unittest
{
    Engine engine = new Engine();
    engine.start();

    /**
    * Let the event engine know what typeIDs are
    * allowed to be queued
    */
    engine.addQueue(1);
    engine.addQueue(2);

    /**
    * Create a new Signal Handler that will handles
    * event types `1` and `2` with the given `handler()`
    * function
    */
    class SignalHandler1 : Signal
    {
        this()
        {
            super([1, 2]);
        }

        public override void handler(Event e)
        {
            import std.stdio;

            writeln("Running event", e.id);
        }
    }

    /**
    * Tell the event engine that I want to register
    * the following handler for its queues `1` and `2`
    */
    Signal j = new SignalHandler1();
    engine.addSignalHandler(j);

    Event eTest = new Event(1);
    engine.push(eTest);

    eTest = new Event(2);
    engine.push(eTest);

    Thread.sleep(dur!("seconds")(2));
    engine.push(eTest);

    writeln("naai");

    /* TODO: Before shutting down, actually test it out (i.e. all events ran) */
    engine.shutdown();
}

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
public final class Engine : Thread
{
    /* TODO: Or use a queue data structure */
    private DList!(Queue) queues;
    private Mutex queueLock;

    /* TODO: Or use a queue data structure */
    private DList!(Signal) handlers;
    private Mutex handlerLock;

    private Duration sleepTime;

    private bool running;

    private DList!(DispatchWrapper) threadStore;
    private Mutex threadStoreLock;

    this()
    {
        super(&run);
        queueLock = new Mutex();
        handlerLock = new Mutex();
        threadStoreLock = new Mutex();
    }

    /**
    * Set the event loop sleep time
    *
    * The load average will sky rocket if it is 0,
    * which is just because it is calculated on how
    * full the run queue is, length but also over time
    * and even just one task continousy in it will
    * make the average high
    *
    * Reason why it's always runnable is the process
    * (the "thread") is a tight loop with no sleeps
    * that would dequeue it from the run queue and/or
    * no I/O system calls that would put it into the
    * waiting queue
    */
    public void setSleep(Duration time)
    {
        sleepTime = time;
    }

    /**
    * Adds the given Signal handler
    *
    * @param e the Signal handler to add
    */
    public void addSignalHandler(Signal e)
    {
        /* Lock the signal-set */
        handlerLock.lock();

        /* Add the new handler */
        handlers ~= e;

        /* Unlock the signal-set */
        handlerLock.unlock();
    }

    /**
    * Event loop
    */
    public void run()
    {
        running = true;

        while (running)
        {
            /* TODO: Implement me */

            /**
            * TODO: If lock fails, then yield
            */

            /**
            * Lock the queue-set
            *
            * Additionally:
            * Don't waste time spinning on mutex,
            * if it is not lockable then yield
            */
            while (!queueLock.tryLock_nothrow())
            {
                yield();
            }

            foreach (Queue queue; queues)
            {
                /* If the queue has evenets queued */
                if (queue.hasEvents())
                {
                    /* TODO: Add different dequeuing techniques */

                    /* Pop the first Event */
                    Event headEvent = queue.popEvent();

                    /* Get all signal-handlers for this event type */
                    Signal[] handlersMatched = getSignalsForEvent(headEvent);

                    /* Dispatch the signal handlers */
                    dispatch(handlersMatched, headEvent);

                }
            }

            /* Unlock the queue set */
            queueLock.unlock();

            /* Yield to stop mutex starvation */
            yield();

            /* TODO: Add yield to stop mutex starvation on a single thread */

            /* Sleep the thread */
            // sleepTime = dur!("seconds")(0);
            // sleep(sleepTime);
        }
    }

    /**
    * Stops the event engine
    *
    * TODO: Examine edge cases where this might not work
    */
    public void shutdown()
    {
        /* TODO: Insert a lock here, that dispatch should adhere too as well */

        /* Stop the loop */
        running = false;

        
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
        foreach (Signal signal; signalSet)
        {
            /* Create a new Thread */
            // Thread handlerThread = getThread(signal, e);
            DispatchWrapper handlerThread = new DispatchWrapper(signal, e);

            /**
            * TODO
            *
            * When we call `shutdown()` there may very well be a case of
            * where the threadStoreLock unlocks after the clean up
            * loop, but storeThread hangs here during that time,
            * then proceeds to start the thread, we should therefore,
            * either block on running changed (solution 1, not as granular)
            *
            * Solution 2: Block on dispatch being called <- use this method rather
            * But still needs a running check, it must not go ahead if running is now
            * false
            */

            /* Store the thread */
            storeThread(handlerThread);

            /* Start the thread */
            handlerThread.start();
        }
    }

    /**
    * Store the thread
    *
    * TODO: This can only be implemented if we use
    * wrapper threads that exit, and we can signal
    * removal from thread store then
    */
    private void storeThread(DispatchWrapper t)
    {
        /* Lock the thread store from editing */
        threadStoreLock.lock();

        /* Add the thread */
        threadStore ~= t;

        /* Unlock the thread store for editing */
        threadStoreLock.unlock();
    }

    /**
    * Removes a thread from the thread store
    */
    private void removeThread(DispatchWrapper t)
    {
        /* Lock the thread store from editing */
        threadStoreLock.lock();

        /* Remove the thread */
        threadStore.linearRemoveElement(t);

        /* Unlock the thread store for editing */
        threadStoreLock.unlock();
    }

    /**
    * DispatchWrapper
    *
    * Effectively a thread but with the Signal,
    * Event included with clean-up routines
    */
    private class DispatchWrapper : Thread
    {
        private Signal signal;
        private Event e;

        this(Signal signal, Event e)
        {
            super(&run);
            this.signal = signal;
            this.e = e;
        }

        private void run()
        {
            /* Run the signal handler */
            signal.handler(e);

            /* Remove myself from the thread store */
            removeThread(this);
        }
    }

    /**
    * returns all signal(s) responsible for
    * handling the type of Event provided
    *
    * @param e the Event type to match to
    * @returns Signal[] the list of signal
    * handlers that handle event e
    */
    public Signal[] getSignalsForEvent(Event e)
    {
        /* Matched handlers */
        Signal[] matchedHandlers;

        /* Lock the signal-set */
        handlerLock.lock();

        /* Find all handlers matching */
        foreach (Signal signal; handlers)
        {
            if (signal.handles(e.id))
            {
                matchedHandlers ~= signal;
            }
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

        if (matchedQueue)
        {
            /* Append to the queue */
            matchedQueue.add(e);
        }
    }

    /**
    * Creates a new queue with the given id
    * and then adds it
    *
    * @param id the id of the new queue to add
    * @throws EventyException if a queue with
    * the given id already exists
    */
    public void addQueue(ulong id)
    {
        /* Create a new queue with the given id */
        Queue newQueue = new Queue(id);

        /* Lock the queue collection */
        queueLock.lock();

        /* If no such queue exists then add it (recursive mutex used) */
        if (!findQueue(id))
        {
            /* Add the queue */
            queues ~= newQueue;
        }
        else
        {
            throw new EventyException("Failure to add queue with ID already in use");
        }

        /* Unlock the queue collection */
        queueLock.unlock();
    }

    /**
    * Given an id, this will return
    * the Queue associated with said
    * id
    *
    * @param id the id of the Queue
    * @returns The Queue if found but
    * null otherwise
    */
    public Queue findQueue(ulong id)
    {
        /* Lock the queue collection */
        queueLock.lock();

        /* Find the matching queue */
        Queue matchedQueue;
        foreach (Queue queue; queues)
        {
            if (queue.id == id)
            {
                matchedQueue = queue;
                break;
            }
        }

        /* Unlock the queue collection */
        queueLock.unlock();

        return matchedQueue;
    }

    /* TODO: Add coumentation */
    public ulong[] getTypes()
    {
        /* TODO: Implement me */
        return null;
    }
}