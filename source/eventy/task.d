module eventy.task;

import eventy.result : Result;

/** 
 * Task
 *
 * A task is the unit of execution that a promise is
 * to carry out.
 */
public abstract class Task
{
    public abstract Result worker();

    public final Result doTask()
    {
        return null;
    }
}


/** 
 * SimpleTask
 *
 * A task that returns an empty result
 */
public final class SimpleTask : Task
{
    // TODO: Put worker field here

    // TODO: Take in a lambda that takes in no arguments and executes something which returns void
    this(int x)
    {

    }

    // TODO: worker calls it
    public override Result worker()
    {
        // TODO: Make a result
        Result result;

        // TODO: Call worker-field here
        
        // TODO: You must handle errors and set `result` accordingly

        return result;
    }
}