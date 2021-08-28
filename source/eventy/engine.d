module eventy.engine;

import eventy.queues : Queue;
import eventy.signal : Signal;
import eventy.event : Event;


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
    private Queue[] queues;

    /* TODO: Or use a queue data structure */
    private Signal[] handlers;

    this()
    {

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

    }

    public ulong[] getTypes()
    {
        /* TODO: Implement me */
        return null;
    }
}