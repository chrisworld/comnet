#Create a simulator object
set ns [new Simulator]

# open output files
set f0 [open tcp.tr w]
set f1 [open udp.tr w]

#Open the nam trace file
set nf [open out.nam w]
$ns namtrace-all $nf

# Creates four nodes n0, n1, n2, n3
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

set n4 [$ns node]
set n5 [$ns node]

#Create the following topology, where
#n0 and n1 are connected by a duplex-link with
#capacity 5Mbps, propagation delay 20ms, dropping
#discipline “DropTail”.

$ns duplex-link $n0 $n1 5Mb 20ms DropTail
$ns duplex-link $n4 $n1 5Mb 20ms DropTail

$ns duplex-link $n2 $n3 5Mb 20ms DropTail
$ns duplex-link $n2 $n5 5Mb 20ms DropTail

# n1 and n2 are connected by a duplex-link with
# capacity 0.5Mbps, propagation delay 100ms, and
# dropping discipline “DropTail”.

$ns duplex-link $n1 $n2 0.5Mb 100ms DropTail

# Create a bottleneck between n1 and n2, with a maximum queue
# size of 5 packets

$ns queue-limit $n1 $n2 5

# Instruct nam how to display the
$ns duplex-link-op $n0 $n1 orient right-down
$ns duplex-link-op $n4 $n1 orient right-up
$ns duplex-link-op $n1 $n2 orient right
$ns duplex-link-op $n2 $n3 orient right-up
$ns duplex-link-op $n2 $n5 orient right-down
$ns duplex-link-op $n1 $n2 queuePos 0.5

# Establish a TCP connection between n0 and n3
set tcp [new Agent/TCP]
set udp [new Agent/UDP]
set sink_tcp [new Agent/TCPSink]
set sink_udp [new Agent/LossMonitor]

$ns attach-agent $n0 $tcp
$ns attach-agent $n4 $udp
$ns attach-agent $n3 $sink_tcp
$ns attach-agent $n5 $sink_udp

# connect
$ns connect $tcp $sink_tcp
$ns connect $udp $sink_udp

# Create an FTP transfer (using the TCP agent)
# between n0 and n3
set ftp [new Application/FTP]

set cbr [new Application/Traffic/CBR]
$cbr set packetSize_ 1000
$cbr set rate_ 1Mb

$ftp attach-agent $tcp
$cbr attach-agent $udp

################################
# Define a 'finish' procedure
################################
proc finish {} {
global ns nf f0 f1
$ns flush-trace

# close files
close $f0
close $f1
close $nf

#Execute nam on the trace file
exec nam –a out.nam&
exec xgraph tcp.tr udp.tr -y "bandwidth / Mbps" -x "time / s" -geometry 800x400 &
exit 0
}

################################
# Record
################################

proc record {} {
        global sink_tcp sink_udp f0 f1
        #Get an instance of the simulator
        set ns [Simulator instance]
        #Set the time after which the procedure should be called again
        set time 0.5
        #How many bytes have been received by the traffic sinks?
        set bw0 [$sink_tcp set bytes_]
        set bw1 [$sink_udp set bytes_]
        #Get the current time
        set now [$ns now]
        #Calculate the bandwidth (in MBit/s) and write it to the files
        puts $f0 "$now [expr $bw0/$time*8/1000000]"
        puts $f1 "$now [expr $bw1/$time*8/1000000]"
        #Reset the bytes_ values on the traffic sinks
        $sink_tcp set bytes_ 0
        $sink_udp set bytes_ 0
        #Re-schedule the procedure
        $ns at [expr $now+$time] "record"
}

# Start the data transfer:
$ns at 0.0 "record"
$ns at 0.1 "$ftp start"
$ns at 0.1 "$cbr start"
$ns at 5.0 "$ftp stop"
$ns at 5.0 "$cbr stop"
$ns at 5.1 "finish"

# Launch the animation
$ns run
