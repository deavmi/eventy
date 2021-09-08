module eventy.exceptions;

public final class EventyException : Exception
{
    this(string message)
    {
        super(message);
    }
}