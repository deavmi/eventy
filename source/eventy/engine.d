module eventy.engine;

import eventy.promise : Promise;
import eventy.task : Task;

/** 
 * Engine
 *
 * The core of the event sub-system, this maintains
 * promises, allows introspection and control over them
 * and also allows creating them
 *
 * NOTE: Do we even need this? Promises can track (themselves)
 * who is waiting for them
 */
public class Engine
{
    

    public Promise create(Task task)
    {
        // Create a promise associated with this engine instance
        Promise newPromise = new Promise(this, task);


        return newPromise;
    }
}

 