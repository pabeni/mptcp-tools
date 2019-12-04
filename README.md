# mptcp-tools
misc helpers to test and use the mptcp net-next implementation 

## Contents
use_mptcp/

An utility to force a non MPTCP-enabled application to use MPTCP instead of TCP.

### Usage

    ./use_mptcp.sh <app> <app command line>
    
It will build on the fly wrapper library to hijack the socket() libcall, requires gcc and make
