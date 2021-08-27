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
    private ulong[] typeIDs;

    this(ulong[] typeIDs, EventHandler handler)
    {

    }
}