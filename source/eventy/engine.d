module eventy.engine;

import eventy.types : EventType;
import eventy.signal : Signal;
import eventy.event : Event;
import eventy.config;
import eventy.exceptions;

import std.container.dlist;
import core.sync.mutex : Mutex;
import core.thread : Thread, dur, Duration;
import std.conv : to;

unittest
{
    import std.stdio;

    Engine engine = new Engine();

    /**
    * Let the event engine know what typeIDs are
    * allowed to be queued
    */
    engine.addEventType(new EventType(1));
    engine.addEventType(new EventType(2));

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
            writeln("Running event", e.getID());
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

    while(engine.hasEventsRunning()) {}

    /* TODO: Before shutting down, actually test it out (i.e. all events ran) */
    engine.shutdown();
}

unittest
{
    import std.stdio;

    EngineSettings customSettings = {holdOffMode: HoldOffMode.YIELD};
    Engine engine = new Engine(customSettings);

    /**
    * Let the event engine know what typeIDs are
    * allowed to be queued
    */
    engine.addEventType(new EventType(1));
    engine.addEventType(new EventType(2));

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
            writeln("Running event", e.getID());
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

    while(engine.hasEventsRunning()) {}

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
public final class Engine
{
    /* Registered queues */
    private DList!(EventType) eventTypes;
    private Mutex eventTypesLock;

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
        eventTypesLock = new Mutex();
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
            while(hasEventsRunning()) {}
        }
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
        foreach (Signal signal; signalSet)
        {
            /* Create a new Thread */
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
     * Checks whether or not there are still events
     * running at the time of calling
     *
     * Returns: <code>true</code> if there are events
     * still running, <code>false</code> otherwise
     */
    public bool hasEventsRunning()
    {
        /* Whether there are events running or not */
        bool has = false;

        /* Lock the thread store */
        threadStoreLock.lock();

        has = !threadStore.empty();

        /* Unlock the thread store */
        threadStoreLock.unlock();

        return has;
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
            if (signal.handles(e.getID()))
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
     * Returns: <code>true</code> if a signal handler does
     *          exist, <code>false</code> otherwise
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
        //TODO: New code goes below here
        /** 
         * What we want to do here is to effectively
         * wake up a checker thread and also (before that)
         * perhaps we say what queue was modified
         *
         * THEN the checker thread goes to said queue and
         * executes said event (dispatches it) and then sleep
         * again till it is interrupted. We need Pids and kill etc for this
         *
         * Idea (2)
         *
         * If we cannot do a checker thread then we can spwan a thread here
         * but then we get no control for priorities etc, although actually we could
         * maybe? It depends, we don't want multiple dispathers at same time then
         * (A checker thread would ensure we don't get this)
         */

        /* Obtain all signal handlers for the given event */
        Signal[] handlersMatched = getSignalsForEvent(e);

        /* If we get signal handlers then dispatch them */
        if(handlersMatched.length)
        {
            dispatch(handlersMatched, e);
        }
        /* If there are no matching events */
        else
        {
            //TODO: Add default handler support
            //TODO: Add error throwing in case where not true
        }
    }

    /** 
     * Registers a new EventType with the engine
     * and then adds it.
     * 
     * Throws EventyException if the id of the given
     * EventType is is already in use by another
     *
     * Params:
     *   id = the id of the new event type to add
     * Throws: EventyException
     */
    public void addEventType(EventType evType)
    {
        /* Lock the event types list */
        eventTypesLock.lock();

        /* If no such queue exists then add it (recursive mutex used) */
        if (!findEventType(evType.getID()))
        {
            /* Add the event types list */
            eventTypes ~= evType;
        }
        else
        {
            throw new EventyException("Failure to add EventType with id '"~to!(string)(evType.getID())~"\' as it is already in use");
        }

        /* Unlock the event types list */
        eventTypesLock.unlock();
    }

    /** 
     * Given an if, this will return the EventType
     * associated with said id
     *
     * Params:
     *   id = the id of the EventType
     * Returns: The EventType if found, otherwise
     *          <code>null</code>
     */
    public EventType findEventType(ulong id)
    {
        /* Lock the EventType list */
        eventTypesLock.lock();

        /* Find the matching EventType */
        EventType matchedEventType;
        foreach (EventType eventType; eventTypes)
        {
            if (eventType.getID() == id)
            {
                matchedEventType = eventType;
                break;
            }
        }

        /* Unlock the EventType list */
        eventTypesLock.unlock();

        return matchedEventType;
    }

    /* TODO: Add coumentation */
    private ulong[] getTypes()
    {
        /* TODO: Implement me */
        return null;
    }
}