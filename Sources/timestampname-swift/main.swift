import Foundation

func printHelpAndExit() {
    print("""
          Usage: TimestampNameRust [ options ]
          Options:
              -h          Display help and exit.
              -dry        Only show the operations but do not perform a rename.
              -debug      Enable debug output.
              -noprefix   Do not add numerical prefix to the renamed files
                          (works if not more than one file is shot per second).
              -utc        Do not reinterpret MP4 timestamps into local time zone.
                          Even though specification suggests to use UTC for CreationDate
                          and ModificationDate, some cameras (DJI?) are saving it
                          in a local time zone, so the time zone offset will double
                          if we will apply conversion to local time zone on top of it.
                          This option will produce incorrectly named files if a folder
                          contains video files from DJI and Samsung for example.
          """)
    exit(0)
}

var dryRun = false
var debug = false
var noPrefix = false
var utc = false
var n = 0;
for arg in CommandLine.arguments {
    // TODO there should be a better way to skip program name
    n += 1
    if n == 1 {
        continue
    }
    switch arg {
    case "-h", "--help":
        printHelpAndExit()
    case "-dry":
        dryRun = true
    case "-debug":
        debug = true
    case "-utc":
        utc = true
    case "-noprefix":
        noPrefix = true
    default:
        eprint("Unrecognized argument: \(arg)")
        exit(1)
    }
}

let cmdArgs = CmdArgs(dryRun: dryRun, noPrefix: noPrefix, utc: utc, debug: debug)
do {
    try execute(cmdArgs: cmdArgs)
    exit(0)
} catch {
    eprint("\nUnexpected error: \(error)")
}
exit(1)
