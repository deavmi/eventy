![](logos/logo.png)

Eventy
======

### _Easy-to-use_ event-loop dispatcher framework for D-based applications

---

## Getting started

### The _engine_

The first thing every Eventy-based application will need is an instance of the `Engine`.
This provides the user with a single object instance of the [`Engine` class](https://eventy.dpldocs.info/v0.4.1/eventy.engine.Engine.html) by which
the user can register _event types_, _signal handlers_ for said events and the ability
to trigger or _push_ events into the engine.

The simplest way to get a new _engine_ up and running is as follow:

```d
Engine engine = new Engine();
```

This will create a new engine initializing all of its internals such that it is ready for
use.

### Event types

_Event types_ are effectively just numbers. The use of these is to be able to connect events
pushed into the engine with their respective signal handlers (which are registered to handle
one or more event types).

Let's create two event types, with IDs `1` and `2`:

```d
engine.addEventType(new EventType(1));
engine.addEventType(new EventType(2));
```

This will tell the engine to create two new event types with tags `1` and `2` respectively.

### Signal handlers

We're almost done. So far we have created a new _engine_ for handling our event tyoes and
the triggering of events. What is missing is something to _handle those event types_ when
an event of one of those types is pushed into the engine. Such handlers are referred to as
_signal handlers_ and in Eventy these are instances of the [`Signal` class](https://eventy.dpldocs.info/v0.4.1/eventy.signal.Signal.html).

We're going to create a signal that can handle both of the event types `1` and `2` that we
registered earlier on. We can do this by creating a class that inherits from the `Signal`
base class:

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
   		writeln("Running event", e.getID());
   	}
}
```

We need to tell the `Signal` class two things:

1. What _event typess_ it will handle
2. What to _run_ for said event types

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
for those event types).

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

Despite us pushing the events into the engine in the order of `1` and _then_ `2`, the
scheduling of such threads is up to the Linux kernel and hence one could be run before
the other.

---

## Release notes

### `v0.4.0`

```
Completely overhauled Eventy system for the v0.4.0 release

Removed the event-loop for a better system (for now) whereby we just dispatch signal handlers on the call to `push(Event)`.

In a future release I hope to bring the event loop back but in a signal-based manner, such that we can support deferred events and priorities and such
```