module eventy.event;

/** 
 * Event
 *
 * An Event represents a trigger for a given signal(s)
 * handlers which associate with the given typeID
 */
public class Event
{
    /* The event's type id */
    private ulong id;

    /** 
     * Creates a new Event with the given typeID
     *
     * Params:
     *   typeID = the new Event's type ID
     */
    this(ulong typeID)
    {
        this.id = typeID;
    }

    /** 
     * Returns the type ID of this Event
     *
     * Returns: The Event's type ID
     */
    public final ulong getID()
    {
        return id;
    }
}
