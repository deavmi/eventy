module eventy.exceptions;

/** 
 * EventyException
 *
 * An Eventy runtime error
 */
public final class EventyException : Exception
{
    this(string message)
    {
        super(message);
    }
}