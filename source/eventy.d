module eventy;

import core.thread : Thread;
import std.container.dlist : DList;
import core.sync.mutex : Mutex;

public class EventManager : Thread
{
	/* List of signals than we can expect */
	private Signal[] signals;
	private Mutex signalMutex;
	
	/* Recieved signals */
	private DList!(ulong) signalInbox;
	private Mutex signalInboxMutex;

	this()
	{
		/* Initialize the signal queue */
	}

	/**
	* Event loop
	*/
	private void eventLoop()
	{
		while(true)
		{
			/* Whether or not there is anything to process */
			bool isEmpty;

			/* The signal ID to be processed */
			ulong currentID;

			/* Lock the signal inbox */
			signalInboxMutex.lock();

			/* Check whether or not it is empty */
			isEmpty = signalInbox.empty();

			/* If it is not empty then dequeue a signal */
			if(!isEmpty)
			{
				currentID = signalInbox.front();
				signalInbox.removeFront(1);
			}

			/* Unlock the signal inbox */
			signalInboxMutex.unlock();

			/* Only process if we got something */
			if(!isEmpty)
			{
				/* Find the matching Signal */
				Signal matchingSignal = findSignal(currentID);

				/* Get the Signal's Event(s) */
				Event[] signalHandlers = matchingSignal.getEvents();

				/* Dispatch all events */
				foreach(Event signalHandler; signalHandlers)
				{
					/* Dispatch the current signal handler */
					signalHandler.run();
				}
			}
		}
	}

	/**
	* Attach a new Signal to the event loop that
	* can then be triggered with signal(ulong id)
	*/
	public void attachSignal(Signal signal)
	{

	}

	private Signal findSignal(ulong id)
	{
		/* The matching Signal */
		Signal matchingSignal;

		/* Lock the signal registry */
		signalMutex.lock();

		/* Find the matching Signal */
		foreach(Signal signal; signals)
		{
			if(signal.getID() == id)
			{
				matchingSignal = signal;
				break;
			}
		}

		/* Unllcok the signal registry */
		signalMutex.unlock();

		return matchingSignal;
	}

	/*
	* Sends a signal by putting it in the signal queue
	*
	*/
	public void signal(ulong id)
	{

	}
}

/**
* Signal
*
* A signal is associates a unique number (used to trigger
* the signal) with an event to be run on reception of the
* signal
*/
public final class Signal
{
	/* The Event to trigger on reception of this signal */
	private Event[] triggerEvents;

	/* Unique signal ID */
	private ulong ID;

	/* Get the events */
	public Event[] getEvents()
	{
		return triggerEvents;
	}

	/* Get this Signal's unique identifier */
	public ulong getID()
	{
		return ID;
	}
}

public final class Event
{
	/* The function to call when this event is ran */
	private void function() handler;

	/* Whether or not a new thread should be spwaned for running this event */
	private bool spawnThread;

	/**
	* Constructs a new Event with the given function to be
	* run, `handler`, and whether or not a new thread should
	* be spawned to run the handler, `spawnThread`, which
	* is `false` by default
	*/
	this(void function() handler, bool spawnThread = false)
	{
		this.handler = handler;

		/* TODO: Handle `spwanThread` = true */
		this.spawnThread = spawnThread;
	}

	public void run()
	{
		/* Call on this thread if spawnThread = false */
		if(!spawnThread)
		{
			handler();
		}
		/* Call on a new thread if spawnThread = true */
		else
		{
			/* Create the new thread with the handler function */
			Thread eventHandlerThread = new Thread(handler);

			/* Start the thread */
			eventHandlerThread.start();
		}
		
	}
}