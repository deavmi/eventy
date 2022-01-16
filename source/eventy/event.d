module eventy.event;

/**
* Event
*
* An Event represents a trigger for a given signal(s)
* handlers which associate with the given typeID
*
* It can optionally take a payload with it as well
*/
public class Event
{
    /**
    * Creates a new Event, optionally taking with is a
    * payload
    */
    this(ulong typeID, ubyte[] payload = null)
    {
        this.id = typeID;
        this.payload = payload;
    }

    ulong id;
    ubyte[] payload;
}
