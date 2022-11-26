module eventy.config;

import core.thread : Duration, dur;

/**
 * Configuration system for eventy
 *
 * Allows the user to specify certain
 * tweaks to the engine
 */
public struct EngineSettings
{
    /* Agressive lock trying (can starve the loop-check) */
    bool agressiveTryLock;

    /* Hold-off mode */
    HoldOffMode holdOffMode;

    /* If `holdOffMode` is `SLEEP` then set the duration for the sleep */
    Duration sleepTime;
}

/**
 * 
 */
public enum HoldOffMode
{
    YIELD,
    SLEEP
}