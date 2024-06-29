const std = @import("std");
const logErr = std.log.err;
pub fn main() !u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var argsIterator = try std.process.argsWithAllocator(allocator);
    defer argsIterator.deinit();

    var args = std.ArrayList([:0]const u8).init(allocator);
    defer args.deinit();

    var processName: []const u8 = undefined;

    if (!argsIterator.skip()) {
        // I guess this is the error code for invalid cli args
        return 127;
    }
    var i: u8 = 0;
    while (argsIterator.next()) |arg| : (i += 1) {
        if (i == 0) processName = arg;
        try args.append(arg);
        //Todo: handle process passed arguments
    }
    const startTime = try std.time.Instant.now();
    var runningProcess = std.process.Child.init(try args.toOwnedSlice(), allocator);
    const procResult = runningProcess.spawnAndWait() catch |err| {
        //Todo: implement a verbose mode when logging (pid maybe)
        logErr("Process:'{s}'  couldn't be spawned due to [{s}]", .{ processName, @errorName(err) });
        return 127;
    };
    switch (procResult) {
        .Exited => |exitCode| if (exitCode != 0) {
            logErr("Process  '{s}' exited with non zero status {}", .{ processName, exitCode });
        },
        .Signal => |signal| {
            logErr("Process: '{s}' exited by signal {}", .{ processName, signal });
        },
        .Stopped => |sigCode| {
            logErr("Process: '{s}' stopped by signal {}", .{ processName, sigCode });
        },
        .Unknown => {
            logErr("Process: '{s}' exited with unknown status", .{processName});
        },
    }

    const elapsed = (try std.time.Instant.now()).since(startTime);
    //Todo: implement logging options
    std.debug.print("Process '{s}' exited successfully in {any} ms\n", .{ processName, std.fmt.fmtDuration(elapsed) });
    return 0;
}
