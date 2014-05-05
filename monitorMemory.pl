#!/usr/bin/perl -w
#######################################################################################
# monitorMemory.pl
# Written by: Brandon Zehm <caspian@dotconf.net>
# 
# Purpose:
#   To monitor memory and swap usage, sending information
#   to the system log.
#
# Technical Description:
#   Runs a `cat /proc/meminfo` and parses the output.
#   /usr/local/bin/syslog.pl (written by me) to print
#   results to the syslog server.
#
# Changelog
#   01/20/2004 - v1.20
#         - Require a -r option to run.
#         - Added a -l option for logging to a file
#         - Textual changes to most error messages.
#
#   v1.02 - Removed syslog priority of ERROR. Increased
#           swap warning threshold to 35.
#
#   v1.01 - Fixed a few possible divide by zero errors
#
#######################################################################################
use strict;

## Global Variable(s)
my %conf = (
    "programName"          => 'monitorMemory.pl',
    "version"              => '1.20',
    "authorName"           => 'Brandon Zehm',                    ## Information about the author or owner of this script.
    "authorEmail"          => 'brandon.zehm@hp.com',
    "hostname"             => $ENV{'HOSTNAME'},                  ## Used in printmsg() for all output.
    
    "syslogProgram"        => "/usr/local/bin/syslog.pl",
    
    "run"                  => 0,                                 ## Whether we should run script or not
    "debug"                => 0,
    "stdout"               => 0,
    "syslog"               => 1,                                 ## Syslog messages by default (--stdout disables this)
    "facility"             => "USER",
    "priority"             => "INFO",
    "logging"              => '',                                ## If this is true the printmsg function prints to the log file
    "logFile"              => '',                                ## If this is specified (form the command line via -l) this file will be used for logging.
    
    ## Set some thresholds, this just changes the message printed and the syslog priority.
    "thresholdWARNING"     => 80,
    "thresholdERROR"       => 85,
    "thresholdCRIT"        => 95,
    "thresholdEMERG"       => 99,
    "thresholdSwapWARNING" => 50,
);







#############################
##
##      MAIN PROGRAM
##
#############################

## Initialize
initialize();

## Process Command Line
processCommandLine();

## Open the log file if we need to
if ($conf{'logFile'}) {
    if ($conf{'logging'}) {
        $conf{'logging'} = 0;
        close LOGFILE;
    }
    if (openLogFile($conf{'logFile'})) { quit("OS-ERROR => Opening the log file [$conf{'logFile'}] returned the error: $!", 1); }
}

## Get memory info from the kernel
my @input = ();
for (my $counter = 0; $counter <= 10; $counter++, sleep(10)) {
    quit("OS-ERROR => 10 consecutive errors while trying to read /proc/meminfo", 1) if ($counter >= 10);
    open(FILE, "/proc/meminfo") or next;
    @input = <FILE>;
    close FILE;
    chomp @input;
    last if ($input[2]);
}

my %info = ();

## Go through the output and get some values
foreach (@input) {

  printmsg("processing meminfo line: $_", 3);
  
  ## Drop a few lines we don't care about (2.6 kernel doesn't have these lines)
  if ($_ =~ /^\s*(total:|Mem:|Swap:)\s+/) {
      printmsg("ignoring worthless line: $_", 2);
      next;
  }  
  
  ## Get the total amount of RAM
  if ($_ =~ /^(MemTotal:\s+)(\d+)(\s+.*)/) {
      $info{'ramTotal'} = $2;
      printmsg("Got MemTotal: $2", 2);
  }
  
  ## Get the amount of free RAM
  if ($_ =~ /^(MemFree:\s+)(\d+)(\s+.*)/) {
      $info{'ramFree'} = $2;
      printmsg("Got MemFree: $2", 2);
  }
  
  ## Get the amount of RAM used by buffers
  if ($_ =~ /^(Buffers:\s+)(\d+)(\s+.*)/) {
      $info{'ramBuffers'} = $2;
      printmsg("Got Buffers: $2", 2);
  }
  
  ## Get the amount of RAM used for cache
  if ($_ =~ /^(Cached:\s+)(\d+)(\s+.*)/) {
      $info{'ramCache'} = $2;
      printmsg("Got Cached: $2", 2);
  }
  
  ## Get the amount of total Swap
  if ($_ =~ /^(SwapTotal:\s+)(\d+)(\s+.*)/) {
      $info{'swapTotal'} = $2;
      printmsg("Got SwapTotal: $2", 2);
  }
  
  ## Get the amount of free Swap
  if ($_ =~ /^(SwapFree:\s+)(\d+)(\s+.*)/) {
      $info{'swapFree'} = $2;
      printmsg("Got SwapFree: $2", 2);
  }
  
}

## The actual amount of 'available' ram.
$info{'ramTotalAvailable'} = ($info{'ramFree'} + $info{'ramCache'} + $info{'ramBuffers'});

## Deduce used RAM percentage -- basically do this:  percentage = ( (TOTAL - (FREE + CAHCED + BUFFERS) ) / TOTAL )
if ($info{'ramTotal'}) {
    $info{'ramUsedPercentage'} = sprintf("%d", ((($info{'ramTotal'} - $info{'ramTotalAvailable'} ) / $info{'ramTotal'} ) * 100) );
}
else {
    $info{'ramUsedPercentage'} = 0;
}

## Deduce used Swap percentage
if ($info{'swapTotal'}) {
    $info{'swapUsedPercentage'} = sprintf("%d", ((($info{'swapTotal'} - $info{'swapFree'}) / $info{'swapTotal'}) * 100) );
}
else {
    $info{'swapUsedPercentage'} = 0;
}

## Decide how urgent this is:
    
  ## EMERGENCY ##
  if ( $info{'ramUsedPercentage'} >= $conf{'thresholdEMERG'}) {
    $conf{'priority'} = "EMERG";
  } 

  ## CRIT ##
  elsif ( $info{'ramUsedPercentage'} >= $conf{'thresholdCRIT'} ) {
    $conf{'priority'} = "CRIT";
  } 

  ## ERROR ##
  elsif ( $info{'ramUsedPercentage'} >= $conf{'thresholdERROR'} ) {
    $conf{'priority'} = "ERR";
  }

  ## WARNING ##
  elsif ( $info{'ramUsedPercentage'} >= $conf{'thresholdWARNING'} ) {
    $conf{'priority'} = "WARNING";
  }
  
  else {
    $conf{'priority'} = "INFO";
  }
  
  ## Set priority to WARNING if swap is above allowed limits
  if ( ($info{'swapUsedPercentage'} >= $conf{'thresholdSwapWARNING'}) and ($conf{'priority'} eq "INFO") ) {
    $conf{'priority'} = "WARNING";
  }
  
  ## Generate an output message
  $info{'message'} = "OS-$conf{'priority'} => RAM used: [$info{'ramUsedPercentage'}\%], with [$info{'ramTotalAvailable'} KB] free.  Swap used [$info{'swapUsedPercentage'}\%], with [$info{'swapFree'} KB] free.";
  
  ## Syslog the message (or print it to stdout)
  printmsg($info{'message'}, 0);



## Quit
quit("",0);
































######################################################################
## Function:    help ()
##
## Description: For all those newbies ;) 
##              Prints a help message and exits the program.
## 
######################################################################
sub help {
print <<EOM;

$conf{'programName'}-$conf{'version'} by $conf{'authorName'} <$conf{'authorEmail'}>

Checks memory and swap usage.  The system syslog is used for 
any generated messages unless the --stdout option is used.
  
Usage:  $conf{'programName'} [options]

  Required:
    -r                        run script
  
  Optional:
    --stdout                  print messages to STDOUT rather than the syslog.
    --facility=[0-11]         syslog facility (1/USER is used by default)
    -l <logfile>              enable logging to the specified file
    -v                        verbosity - use multiple times for greater effect

EOM
quit("", 1);
}










######################################################################
##  Function: initialize ()
##  
##  Does all the script startup jibberish.
##  
######################################################################
sub initialize {

    ## Set STDOUT to flush immediatly after each print  
    $| = 1;

    ## Intercept signals
    $SIG{'QUIT'}  = sub { quit("$$ - EXITING: Received SIG$_[0]", 1); };
    $SIG{'INT'}   = sub { quit("$$ - EXITING: Received SIG$_[0]", 1); };
    $SIG{'KILL'}  = sub { quit("$$ - EXITING: Received SIG$_[0]", 1); };
    $SIG{'TERM'}  = sub { quit("$$ - EXITING: Received SIG$_[0]", 1); };
  
    ## ALARM and HUP signals are not supported in Win32
    unless ($^O =~ /win/i) {
        $SIG{'HUP'}   = sub { quit("$$ - EXITING: Received SIG$_[0]", 1); };
        $SIG{'ALRM'}  = sub { quit("$$ - EXITING: Received SIG$_[0]", 1); };
    }
   
    ## Make sure the path is sane
    $ENV{'PATH'} .= ":/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin";
  
    ## Fixup $conf{'hostname'}
    if ($conf{'hostname'}) {
        $conf{'hostname'} = $conf{'hostname'};
        $conf{'hostname'} =~ s/\..*$//;
    }
    else {
        $conf{'hostname'} = "unknown";
    }
  
    return(1);
}









######################################################################
##  Function: processCommandLine ()
##  
##  Processes command line storing important data in global var %conf
##  
######################################################################
sub processCommandLine {
    
    ############################
    ##  Process command line  ##
    ############################
    
    my @ARGS = @ARGV;
    my $numargv = @ARGS;
    my $counter = 0;
    for ($counter = 0; $counter < $numargv; $counter++) {
        
        if ($ARGV[$counter] =~ s/^--stdout//i) {             ## stdout ##
          $conf{'stdout'} = 1;
        }
        
        elsif ($ARGV[$counter] =~ s/^--facility=//i) {       ## Facility ##
          $conf{'facility'} = $';
        }
        
        elsif ($ARGS[$counter] =~ /^-r$/) {                  ## Run
            $conf{'run'} = 1;
        }
        
        elsif ($ARGS[$counter] =~ /^-l$/) {                  ## Log File ##
            $counter++;
            $conf{'logFile'} = $ARGS[$counter];
        }
        
        elsif ($ARGS[$counter] =~ s/^-v+//i) {               ## Verbosity ##
            $conf{'debug'} += (length($&) - 1);
        }
        
        elsif ($ARGV[$counter] =~ /^-h$|^--help$/i) {        ## Help ##
            help();
        }
        
        else {                                               ## Unknown Option ##
            quit("OS-ERROR => The option [$ARGS[$counter]] is unknown. Try --help", 1);
        }
        
    }
  
    ## If the user didn't use a -r print the help
    if ($conf{'run'} == 0) {
        help();
    }
  
    return(0);
}
















###############################################################################################
##  Function:    printmsg (string $message, int $level)
##
##  Description: Handles all messages - 
##               Depending on the state of the program it will log
##               messages to a log file, print them to STDOUT or both.
##               
##
##  Input:       $message          A message to be printed, logged, etc.
##               $level            The debug level of the message. If not defined 0
##                                 will be assumed.  0 is considered a normal message, 
##                                 1 and higher is considered a debug message.
##  
##  Output:      Prints to STDOUT, to LOGFILE, both, or none depending 
##               on the state of the program and the debug level specified.
##  
##  Example:     printmsg("ERROR => The file could not be opened!", 0);
###############################################################################################
sub printmsg {
    ## Assign incoming parameters to variables
    my ( $message, $level ) = @_;
    
    ## Make sure input is sane
    $level = 0 if (!defined($level));
    
    ## Continue only if the debug level of the program is >= message debug level.
    if ($conf{'debug'} >= $level) {
        
        ## Get the date in the format: Dec  3 11:14:04
        my ($sec, $min, $hour, $mday, $mon) = localtime();
        $mon = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')[$mon];
        my $date = sprintf("%s %02d %02d:%02d:%02d", $mon, $mday, $hour, $min, $sec);
    
        ## Syslog the message is needed
        if ($conf{'syslog'}) {
            system( qq{$conf{'syslogProgram'} --facility=$conf{'facility'} --priority=$conf{'priority'} "$conf{'programName'}: $message" });
        }
        
        ## Print to STDOUT always if debugging is enabled, or if conf{stdout} is true.
        if ( ($conf{'debug'} >= 1) or ($conf{'stdout'} == 1) ) {
            print "$date $conf{'hostname'} $conf{'programName'}: $message\n";
        }
        
        ## Print to the log file if $conf{'logging'} is true
        if ($conf{'logging'}) {
            print LOGFILE "$date $conf{'hostname'} $conf{'programName'}: $message\n";
        }
        
    }
    
    ## Return 0 errors
    return(0);
}














###############################################################################################
## FUNCTION:    
##   openLogFile ( $filename )
## 
## 
## DESCRIPTION: 
##   Opens the file $filename and attaches it to the filehandle "LOGFILE".  Returns 0 on success
##   and non-zero on failure.  Error codes are listed below, and the error message gets set in
##   global variable $!.
##   
##   
## Example: 
##   openFile ("/var/log/scanAlert.log");
##
###############################################################################################
sub openLogFile {
    ## Get the incoming filename
    my $filename = $_[0];
    
    ## Make sure our file exists, and if the file doesn't exist then create it
    if ( ! -f $filename ) {
        printmsg("NOTICE => The file [$filename] does not exist.  Creating it now with mode [0600].", 0);
        open (LOGFILE, ">>$filename");
        close LOGFILE;
        chmod (0600, $filename);
    }
    
    ## Now open the file and attach it to a filehandle
    open (LOGFILE,">>$filename") or return (1);
    
    ## Put the file into non-buffering mode
    select LOGFILE;
    $| = 1;
    select STDOUT;
    
    ## Tell the rest of the program that we can log now
    $conf{'logging'} = "yes";
    
    ## Return success
    return(0);
}











######################################################################
##  Function:    quit (string $message, int $errorLevel)
##  
##  Description: Exits the program, optionally printing $message.  It 
##               returns an exit error level of $errorLevel to the 
##               system  (0 means no errors, and is assumed if empty.)
##               If your exiting with a non-zero error status $message
##               is also sent to syslogd.
##
##  Example:     quit("Exiting program normally", 0);
######################################################################
sub quit {
    my %incoming = ();
    (
        $incoming{'message'},
        $incoming{'errorLevel'}
    ) = @_;
    $incoming{'errorLevel'} = 0 if (!defined($incoming{'errorLevel'}));
    
    ## Quit messages get printed to the console
    $conf{'mode'} = "stdout";
    
    ## Print exit message
    if ($incoming{'message'}) { 
        printmsg($incoming{'message'}, 0);
    }
    
    ## Exit
    exit($incoming{'errorLevel'});
}






