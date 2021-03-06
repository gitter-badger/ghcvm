package ghcvm.runtime;

#include "Rts.h"

import ghcvm.runtime.types.*;
import ghcvm.runtime.closure.*;

public class RtsMain {
    public static int hsMain(String[] args, CLOSURE_PTR mainClosure, RtsConfig config) {
        int exitStatus = 0;
        SchedulerStatus status = null;
        Ptr<Capability> capPtr = null;

        RtsStartup.hsInit(args, config);

        Capability cap = Rts.lock();
        capPtr = new Ptr<Capability>(cap);
        Rts.evalLazyIO(capPtr, mainClosure, null);
        status = Rts.getSchedStatus(cap);
        Rts.unlock(cap);

        switch (status) {
            case Killed:
                RtsMessages.errorBelch("main thread exited (uncaught exception)");
                exitStatus = EXIT_KILLED;
                break;
            case Interrupted:
                RtsMessages.errorBelch("interrupted");
                exitStatus = EXIT_INTERRUPTED;
                break;
            case HeapExhausted:
                exitStatus = EXIT_HEAPOVERFLOW;
                break;
            case Success:
                exitStatus = EXIT_SUCCESS;
                break;
            default:
                RtsMessages.barf("main thread completed with invalid status");
        }
        RtsStartup.shutdownHaskellAndExit(exitStatus, false);
        // This return is never seen since shutdownHaskellAndExit() will
        // terminate the process. It's there to keep javac happy.
        return exitStatus;
    }
}
