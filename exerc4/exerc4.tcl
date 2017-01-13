#Create a simulator object
set ns [new Simulator]

#Open the nam trace file
set nf [open out.nam w]
$ns namtrace-all $nf

#Define a 'finish' procedure
proc finish {} {
global ns nf $ns
flush-trace
#Close the trace file
close $nf
#Execute nam on the trace file
exec nam –a out.nam&
exit 0
}

# Creates four nodes n0, n1, n2, n3
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

#Create the following topology, where
#n0 and n1 are connected by a duplex-link with
#capacity 5Mbps, propagation delay 20ms, dropping
#discipline “DropTail”.

$ns duplex-link $n0 $n1 5Mb 20ms DropTail
$ns duplex-link $n2 $n3 5Mb 20ms DropTail

# n1 and n2 are connected by a duplex-link with
# capacity 0.5Mbps, propagation delay 100ms, and
# dropping discipline “DropTail”.

$ns duplex-link $n1 $n2 0.5Mb 100ms DropTail


# Create a bottleneck between n1 and n2, with a maximum queue
# size of 5 packets

$ns queue-limit $n1 $n2 5

# Instruct nam how to display the
$ns duplex-link-op $n0 $n1 orient right
$ns duplex-link-op $n1 $n2 orient right
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n1 $n2 queuePos 0.5

# Establish a TCP connection between n0 and n3
set tcp [new Agent/TCP]
$ns attach-agent $n0 $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n3 $sink
$ns connect $tcp $sink

# Create an FTP transfer (using the TCP agent)
# between n0 and n3
set ftp [new Application/FTP]
$ftp attach-agent $tcp

# Start the data transfer:
$ns at 0.1 “$ftp start"
$ns at 5.0 “$ftp stop"
$ns at 5.1 “finish”

# Launch the animation
$ns run
