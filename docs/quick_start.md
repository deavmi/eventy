## Getting started

### The _engine_

The first thing every Eventy-based application will need is an instance of the `Engine`.
This provides the user with the basic event-loop functionality that eventy provides. It's
the core of the whole framework that exists to have event-triggers ingested into its
_queues_, checking those _queues_ and one by one dispatching each _signal handler_ that
is associated with each queue on each item in the queue.

The simplest way to get a new _engine_ up and running is as follow:

```d
Engine engine = new Engine();
engine.start();
```

This will create a new engine initializing all of its internals and then start it as well.

### Queues

_Queues_ are as they sound, a list containing items. Each queue has a unique ID which we
can choose. The items of each queue will be the _events_ that are pushed into the _engine_.
An _event_ has an ID associated with it which tells the _engine_ which queue it must be
added to!

Let's create two queues, with IDs `1` and `2`:

```d
engine.addQueue(1);
engine.addQueue(2);
```

This will tell the engine to create two new queues with tags `1` and `2` respectively.

### Event handlers

We're almost done. So far we have created a new _engine_ for handling our queues and
the triggering of events. What is missing is something to _handle those queues_ when
they have something added to them, we call this an _"event handler"_ in computer science
but this is Eventy, and in Eventy this is known as a `Signal`.

We're going to create a signal that can handle both the queues and perform the same task
for both of them. We do this by creating a class that inherits from the `Signal` base type:

```d
class SignalHandler1 : Signal
{
   	this()
   	{
   		super([1,2]);
   	}
    
    public override void handler(Event e)
   	{
   		import std.stdio;
   		writeln("Running event", e.id);
   	}
}
```

We need to tell the `Signal` class two things:

1. What _queue IDs_ it will handle
2. What to _run_ for said queues

---

The first of these two is very easy, this is what you see in the constructor `this()`:

```d
this()
{
    super([1,2]);
}
```

The `super([1,2])` call tells the Signal class that this signal handler handles those
two IDs, namely `1` and `2`.

---

As for _what to run_, that is specified by overriding the `void handler(Event)` method
in the `Signal` class. In our case we make it write to the console the ID of the event
(which would end up either being `1` or `2` seeing as this handler is only registered
for those queue IDs).

```d
import std.stdio;
writeln("Running event", e.id);
```

---

We're almost there, trust me. The last thing to do is to register this signal handler
with the engine, we do so as follows:

```d
Signal j = new SignalHandler1();
engine.addSignalHandler(j);
```

### Triggering events

Now comes the fun part, you can add events into the system by _pushing them to the core_
as follows:

```d
Event eTest = new Event(1);
engine.push(eTest);

eTest = new Event(2);
engine.push(eTest);


```

You will then see something like this:

```
Running event1
Running event2
```

or:

```
Running event1
Running event2
```

The reason is it depends on which process gets shceduled by the Linux kernel first, this
is because new threads (special types of processes) are spanwed on the dispatch of each
event.