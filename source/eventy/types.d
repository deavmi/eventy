module eventy.types;

import eventy.event : Event;
import core.sync.mutex : Mutex;
import std.container.dlist;
import std.range;

/**
* EventType
*
* Represents a type of event. Every Event has an EventType
* and Signal(s)-handlers register to one or more of these
* types to handle
*/
public final class EventType
{
    /* The EventType's ID */
    private ulong id;

    /** 
     * Instantiates a new EventType with the given id
     *
     * Params:
     *   id = The EventType's id
     */
    this(ulong id)
    {
        this.id = id;
    }

    /** 
     * Returns the id of this EventType
     *
     * Returns: The id of this EventType
     */
    public ulong getID()
    {
        return id;
    }
}