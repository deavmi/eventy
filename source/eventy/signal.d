module eventy.signal;

import eventy.event : Event;

/**
* Signal
*
* Represents a signal handler that handles a given set of typeIDs
* which means that it contains an associated function to be run
* on handling of a given Event
*/
alias EventHandler = void function(Event);

public class Signal
{
    /* TypeIDs this signal handler associates with */
    private ulong[] typeIDs;

    /* Signal handler */
    private EventHandler handler;

    this(ulong[] typeIDs, EventHandler handler)
    {
        this.typeIDs = typeIDs;
        this.handler = handler;
    }

    /**
    * Returns true if this signal handles the given typeID
    * false otherwise
    */
    public bool handles(ulong typeID)
    {
        /* FIXME: Implement */
        return true;
    }

    public void registerTypeID(ulong typeID)
    {

    }

    public void deregisterTypeID(ulong typeID)
    {
        
    }

    public EventHandler getHandler()
    {
        return handler;
    }
}