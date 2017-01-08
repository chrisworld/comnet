# ==================================================================#
# 				Options			    	    #
# ==================================================================#

set val(rp)       DSDV                     ;# ad-hoc routing protocol  
set val(ll)       LL                       ;# Link layer type
set val(mac)      Mac/802_11               ;# MAC type
set val(ifq)      Queue/DropTail/PriQueue  ;# Interface queue type
set val(ifqlen)   50                       ;# max packets in ifq
set val(ant)      Antenna/OmniAntenna      ;# Antenna type
set val(prop)     Propagation/TwoRayGround ;# radio-propagation model
set val(netif)    Phy/WirelessPhy          ;# network interface type
set val(chan)	  Channel/WirelessChannel  ;# channel type

set val(x)		400		   ;# horizontal dimension
set val(y)		400		   ;# vertical dimension
set val(nn)       	5                  ;# number of wireless nodes
set val(stop)		150.0		   ;# end time of simulation
set val(tr)		out.tr	 	   ;# name of the trace file

# MAC
Mac/802_11 set dataRate_ 11Mb
# RTS/CTS
Mac/802_11 set RTSThreshold_ 3000

# ==================================================================#
# 		         General setup			 	    #
# ==================================================================#

# Create simulator
set ns_    [new Simulator]

# Set up trace file
set tracefd [open $val(tr) w]
$ns_ trace-all $tracefd

# Create the "general operations director"
create-god $val(nn)

# Create and configure topography (used for wireless scenarios)
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)


# ==================================================================#
# 		Nodes configuration and setup			    #
# ==================================================================#

$ns_ node-config -adhocRouting $val(rp) \
        -llType $val(ll) \
        -macType $val(mac) \
        -ifqType $val(ifq) \
        -ifqLen $val(ifqlen) \
        -antType $val(ant) \
        -propType $val(prop) \
        -phyType $val(netif) \
        -channel [new $val(chan)] \
        -topoInstance $topo \
        -agentTrace ON \
        -routerTrace OFF \
        -macTrace OFF \
        -movementTrace OFF

# Creating nodes
for {set i 1} {$i <= $val(nn) } {incr i} {
        set node_($i) [$ns_ node $i]
}

$node_(1) set X_ 100.0
$node_(1) set Y_ 346.4
$node_(2) set X_ 0.0
$node_(2) set Y_ 173.2
$node_(3) set X_ 200.0
$node_(3) set Y_ 173.2
$node_(4) set X_ 100.0
$node_(4) set Y_ 0.0
$node_(5) set X_ 300.0
$node_(5) set Y_ 0.0


# ==================================================================#
# 			Agents					    #
# ==================================================================#

# 1500 - 20 byte IP header - 40 byte TCP header = 1440 bytes
Agent/TCP set packetSize_ 1440 ;# This size EXCLUDES the TCP header

for {set i 1} {$i <= $val(nn)} {incr i 1} {
	set agent($i) [new Agent/TCP]
	$ns_ attach-agent $node_($i) $agent($i)

	set sink($i) [new Agent/TCPSink]
	$ns_ attach-agent $node_($i) $sink($i)

	set app($i) [new Application/FTP]
	$app($i) attach-agent $agent($i)
}

$ns_ connect $agent(1) $sink(5)

# Start times for traffic sources
$ns_ at 20.0 "$app(1) start"

# End times for traffic sources
$ns_ at $val(stop) "$app(1) stop"

# End the simulation
$ns_ at $val(stop).1 "finish"
$ns_ at $val(stop).2 "$ns_ halt"

# ==================================================================#
# 				End				    #
# ==================================================================#

# Calling some external programs
proc finish {} {
exec awk -f fil1.awk out.tr > node_1.xgr

exec xgraph node_1.xgr &
puts "Finsihing ns..."
exit 0
}

puts "Starting Simulation..."
$ns_ run
puts "Simulation done."

$ns_ flush-trace
close $tracefd
