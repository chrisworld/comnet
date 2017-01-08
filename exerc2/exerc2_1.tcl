# ==================================================================#
# 				Options			    	    #
# ==================================================================#

set val(rp)       DumbAgent                ;# ad-hoc routing protocol  
set val(ll)       LL                       ;# Link layer type
set val(mac)      Mac/802_11               ;# MAC type
set val(ifq)      Queue/DropTail/PriQueue  ;# Interface queue type
set val(ifqlen)   50                       ;# max packets in ifq
set val(ant)      Antenna/OmniAntenna      ;# Antenna type
set val(prop)     Propagation/TwoRayGround ;# radio-propagation model
set val(netif)    Phy/WirelessPhy          ;# network interface type
set val(chan)	  Channel/WirelessChannel  ;# channel type

set val(x)		500		   ;# horizontal dimension
set val(y)		500		   ;# vertical dimension
set val(nn)       	3                  ;# number of wireless nodes
set val(stop)		150.0		   ;# end time of simulation
set val(tr)		out.tr	 	   ;# name of the trace file

# MAC
Mac/802_11 set dataRate_ 2Mb
# RTS/CTS
Mac/802_11 set RTSThreshold_ 3000
# Carrier sence range
Phy/WirelessPhy set CSThresh_ 3.5e-10

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

$node_(1) set X_ 0.0
$node_(1) set Y_ 0.0
$node_(2) set X_ 250.0
$node_(2) set Y_ 0.0
$node_(3) set X_ 500.0
$node_(3) set Y_ 0.0


# ==================================================================#
# 			Agents					    #
# ==================================================================#

	set agent(1) [new Agent/UDP]
	$ns_ attach-agent $node_(1) $agent(1)
	set agent(3) [new Agent/UDP]
	$ns_ attach-agent $node_(3) $agent(3)

	set sink(2) [new Agent/Null]
	$ns_ attach-agent $node_(2) $sink(2)

	set app(1) [new Application/Traffic/CBR]
	$app(1) set packetSize_ 1000
	$app(1) set interval_ 0.005
	$app(1) attach-agent $agent(1)
	set app(3) [new Application/Traffic/CBR]
	$app(3) set packetSize_ 1000
	$app(3) set interval_ 0.005
	$app(3) attach-agent $agent(3)

$ns_ connect $agent(1) $sink(2)
$ns_ connect $agent(3) $sink(2)

# Start times for traffic sources
$ns_ at 40.0 "$app(1) start"
$ns_ at 100.0 "$app(3) start"

# End times for traffic sources
$ns_ at $val(stop) "$app(1) stop"
$ns_ at $val(stop) "$app(3) stop"

# End the simulation
$ns_ at $val(stop).1 "finish"
$ns_ at $val(stop).2 "$ns_ halt"

# ==================================================================#
# 				End				    #
# ==================================================================#

# Calling some external programs
proc finish {} {
exec awk -f fil1.awk out.tr > node_1.xgr
exec awk -f fil3.awk out.tr > node_3.xgr

exec xgraph node_1.xgr node_3.xgr &
puts "Finsihing ns..."
exit 0
}

puts "Starting Simulation..."
$ns_ run
puts "Simulation done."

$ns_ flush-trace
close $tracefd
