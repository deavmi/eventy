module eventy.engine;

import eventy.queues : Queue;
import eventy.signal : Signal;
import eventy.event : Event;
import eventy.config;
import eventy.exceptions;

import std.container.dlist;
import core.sync.mutex : Mutex;
import core.thread : Thread, dur, Duration;

unittest
{
    import std.stdio;

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

    writeln("done with main thread code");

    while(engine.hasPendingEvents()) {}

    /* TODO: Before shutting down, actually test it out (i.e. all events ran) */
    engine.shutdown();
}

unittest
{
    import std.stdio;

    EngineSettings customSettings = {holdOffMode: HoldOffMode.YIELD};
    Engine engine = new Engine(customSettings);
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

    writeln("done with main thread code");

    while(engine.hasPendingEvents()) {}

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
    /* Registered queues */
    private DList!(Queue) queues;
    private Mutex queueLock;

    /* TODO: Or use a queue data structure */
    /* Registered signal handlers */
    private DList!(Signal) handlers;
    private Mutex handlerLock;

    /* Engine configuration */
    private EngineSettings settings;

    /* Whether engine is running or not */
    private bool running;

    /* Dispatched threads */
    private DList!(DispatchWrapper) threadStore;
    private Mutex threadStoreLock;

    /** 
     * Instantiates a new Eventy engine with the provided
     * configuration
     *
     * Params:
     *   settings = The EngineSettings to use
     */
    this(EngineSettings settings)
    {
        super(&run);

        queueLock = new Mutex();
        handlerLock = new Mutex();
        threadStoreLock = new Mutex();

        this.settings = settings;
    }

    /** 
     * Instantiates a new Eventy engine with the default
     * settings
     */
    this()
    {
        EngineSettings defaultSettings;

        /* Yield if a lock fails (prevent potential thread starvation) */
        defaultSettings.agressiveTryLock = false;

        // FIXME: Investigate ways to lower load average
        // /* Make the event engine loop sleep (1) and for 50ms (2) (TODO: Adjust this) */
        // defaultSettings.holdOffMode = HoldOffMode.SLEEP;
        // defaultSettings.sleepTime = dur!("msecs")(50);

        /* Use yeilding for most responsiveness */
        defaultSettings.holdOffMode = HoldOffMode.YIELD;

        /* Do not gracefully shutdown */
        defaultSettings.gracefulShutdown = false;

        this(defaultSettings);
    }

    /** 
     * Returns the current configuration paremeters being
     * used by the engine
     *
     * Returns: The EngineSettings struct
     */
    public EngineSettings getConfig()
    {
        return settings;
    }

    /** 
     * Updates the current configuration of the engine
     *
     * Params:
     *   newSettings = The new EngineSettings struct to use
     */
    public void setConfig(EngineSettings newSettings)
    {
        this.settings = newSettings;
    }

    /** 
     * Attaches a new signal handler to the engine
     *
     * Params:
     *   e = the signal handler to add
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
     * The main event loop
     *
     * This checks at a certain interval (see HoldOffMode) if
     * there are any events in any of the queues, if so,
     * the dispatcher for said event type is called
     */
    private void run()
    {
        running = true;

        while (running)
        {
            /**
            * Lock the queue-set
            *
            * TODO: Maybe add sleep support here too?
            */
            while (!queueLock.tryLock_nothrow())
            {
                // Don't waste time spinning on mutex, yield if failed
                if(!settings.agressiveTryLock)
                {
                    yield();
                }
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

            /* Activate hold off (dependening on the type) */
            if(settings.holdOffMode == HoldOffMode.YIELD)
            {
                /* Yield to stop mutex starvation */
                yield();
            }
            else if(settings.holdOffMode == HoldOffMode.SLEEP)
            {
                /* Sleep the thread (for given time) to stop mutex starvation */
                sleep(settings.sleepTime);
            }
            else
            {
                /* This should never happen */
                assert(false);
            }
        }
    }

    /** 
     * Shuts down the event engine
     */
    public void shutdown()
    {
        /* TODO: Insert a lock here, that dispatch should adhere too as well */

        /* FIXME: We should prevent adding of queues during shutdown */
        /* FIXME: We should prevent pushing of events during shutdown */

        /* Wait for any pendings events (if configured) */
        if(settings.gracefulShutdown)
        {
            while(hasPendingEvents()) {}
        }

        /* Stop the loop */
        running = false;
    }

    /** 
     * Creates a new thread per signal and dispatches the event to them
     *
     * Params:
     *   signalSet = The signal handlers to use for dispatching
     *   e = the Event to be dispatched to each handler
     */
    private void dispatch(Signal[] signalSet, Event e)
    {
        /* TODO: Add ability to dispatch on this thread */

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
     * Adds a thread to the thread store
     *
     * Params:
     *   t = the thread to add
     */
    private void storeThread(DispatchWrapper t)
    {
        /**
        * TODO: This can only be implemented if we use
        * wrapper threads that exit, and we can signal
        * removal from thread store then
        */

        /* Lock the thread store from editing */
        threadStoreLock.lock();

        /* Add the thread */
        threadStore ~= t;

        /* Unlock the thread store for editing */
        threadStoreLock.unlock();
    }

    /** 
     * Removes a thread from the thread store
     *
     * Params:
     *   t = the thread to remove
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
     * Returns all the signal handlers responsible
     * for handling the type of Event provided
     *
     * Params:
     *   e = the Event type to match to
     * Returns: A Signal[] containing each handler
     *          registered to handle type <code>e</code>
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
     * Checks if there is a signal handler that handles
     * the given event id
     *
     * Params:
     *   id = the event ID to check
     * Returns: 
     */
    public bool isSignalExists(ulong id)
    {
    	return getSignalsForEvent(new Event(id)).length != 0;
    }

    /** 
     * Pushes the given Event into the engine
     * for eventual dispatch
     *
     * Params:
     *   e = the event to push
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
     * and then adds it.
     * 
     * Throws EventyException if the id is already
     * in use by another queue
     *
     * Params:
     *   id = the id of the neq eueue to create
     * Throws: EventyException
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
     * Given an if, this will return the Queue
     * associated with said id
     *
     * Params:
     *   id = the id of the Queue
     * Returns: The Queue if found, otherwise
     *          <code>null</code>
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
    private ulong[] getTypes()
    {
        /* TODO: Implement me */
        return null;
    }


    /** 
     * Checks if any of the queues in the event engine
     * have any pending events in them waiting dispatch
     *
     * Returns: <code>true</code> if there are pending events,
     *          <code>false</code> otherwise
     */
    public bool hasPendingEvents()
    {
        bool isPending = false;

        /* Lock the queues */
        queueLock.lock();

        foreach (Queue queue; queues)
        {
            if (queue.hasEvents())
            {
                isPending = true;
                break;
            }
        }
        
        /* Unlock the queues */
        queueLock.unlock();

        return isPending;
    }
}