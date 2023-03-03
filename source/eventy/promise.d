module eventy.promise;

import eventy.engine : Engine;
import eventy.task : Task;
import core.thread : Thread, Duration, dur;

/** 
 * The state pf the promise
 */
public enum PromiseState
{
    /** 
     * The promise has been created but not yet run
     */
    CREATED,

    /** 
     * The promise is running
     */
    RUNNING,

    /** 
     * The promise has finished running
     */
    FINISHED
}

public class Promise : Thread
{
    /* Our registered engine to report to */
    private Engine engine;

    private PromiseState state;
    private Task task;

    this(Engine engine, Task task)
    {
        // Register this promise with the provided engine
        this.engine = engine;

        // Set our task to execute
        this.task = task;

        // Our state is created
        this.state = PromiseState.CREATED;
    }

    /** 
     * Runs the provided task in a seperate thread
     */
    private void worker()
    {
        // TODO: Task.execute() call here
    }

    public final void execute()
    {

    }

    public final void await()
    {
        await(dur!("seconds")(0));
    }

    public final void await(Duration timeout)
    {

    }
}