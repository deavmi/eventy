Eventy
======

## What I want

```d
// Create en event engine (it logs promises)
Eventy eventy = new Eventy();

/**
 * Create a new promise who's job is to run the
 * provided lambda `(x) => (x*2)`
 */
Promise myPromise = eventy.new((x) => (x*2));

/**
 * Now start the promise and await its completion,
 * this will basically sleep the calling thread
 * till it awakes. It returns a result
 *
 * Internally this calls `this.execute()` and
 * then `await()` on the calling thread (as
 * described above)
 */
Result result = myPromise.await();

/**
 * One can also just start a promise without awaiting it,
 * however the result will have to be grabbed manually later
 */
myPromise.execute();

/**
 * The status of a promise can be checked
 *
 * TODO: There should be a version
 */
if(myPromise.state == State.Finished)
{

}

/**
 * You can call await (it won't start it again)
 * but will rather sleep like await first call.
 *
 * If it has finished then result is returned.
 * It can be called over and over and the result
 * will just be returned.
 */
Result result = myPromise.await();
```