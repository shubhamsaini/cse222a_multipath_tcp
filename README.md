# A comparative study of the Multipath TCP for the Linux kernel

## Download our testbed implementation in VitualBox:
[Google Drive Link](https://drive.google.com/file/d/1x-H1WlIYpDLVZQ48HHZzU_0nNb_NDZ4w/view?usp=sharing)

## Install MPTCP in Ubuntu
Download and MPTCP for Ubuntu 14.04:

    wget -q -O - https://multipath-tcp.org/mptcp.gpg.key | sudo apt-key add - 
    sudo echo "deb https://multipath-tcp.org/repos/apt/debian trusty main" >> /etc/apt/sources.list.d/mptcp.list
    sudo apt-get update
    sudo apt-get install linux-mptcp

Install Grub Customizer. Then move MPTCP kernel to the top of the list.

    sudo add-apt-repository ppa:danielrichter2007/grub-customizer  
    sudo apt-get update  
    sudo apt-get install grub-customizer

Restart and enable MPTCP:

    sudo sysctl -w net.mptcp.mptcp_enabled="1"

To change the congestion control algorithm:

    sudo sysctl -w net.ipv4.tcp_congestion_control="balia"

Available options are cubic, lia, olia, balia, wvegas

## Router 1 configuration
    
    sed -i 's/ubuntu/router1/g' /etc/hostname
    sed -i 's/ubuntu/router1/g' /etc/hosts
    hostname router1
    apt-get update
    apt-get install quagga quagga-doc traceroute
    cp /usr/share/doc/quagga/examples/zebra.conf.sample /etc/quagga/zebra.conf
    cp /usr/share/doc/quagga/examples/ospfd.conf.sample /etc/quagga/ospfd.conf
    chown quagga.quaggavty /etc/quagga/*.conf
    chmod 640 /etc/quagga/*.conf
    sed -i s'/zebra=no/zebra=yes/' /etc/quagga/daemons
    sed -i s'/ospfd=no/ospfd=yes/' /etc/quagga/daemons
    echo 'VTYSH_PAGER=more' >>/etc/environment 
    echo 'export VTYSH_PAGER=more' >>/etc/bash.bashrc
    cat >> /etc/quagga/ospfd.conf << EOF
    interface eth1
    interface eth2
    interface lo
    router ospf
     router-id 1.1.1.1
     passive-interface eth1
     network 192.168.1.0/24 area 0.0.0.0
     network 192.168.2.0/24 area 0.0.0.0
    line vty
    EOF
    cat >> /etc/quagga/zebra.conf << EOF
    interface eth1
     ip address 192.168.1.254/24
     ipv6 nd suppress-ra
    interface eth2
     ip address 192.168.2.220/24
     ipv6 nd suppress-ra
    interface lo
    ip forwarding
    line vty
    EOF
    /etc/init.d/quagga start

## Router 2 Configuration

    sed -i 's/ubuntu/router2/g' /etc/hostname
    sed -i 's/ubuntu/router2/g' /etc/hosts
    hostname router2
    apt-get update
    apt-get install quagga quagga-doc traceroute
    cp /usr/share/doc/quagga/examples/zebra.conf.sample /etc/quagga/zebra.conf
    cp /usr/share/doc/quagga/examples/ospfd.conf.sample /etc/quagga/ospfd.conf
    chown quagga.quaggavty /etc/quagga/*.conf
    chmod 640 /etc/quagga/*.conf
    sed -i s'/zebra=no/zebra=yes/' /etc/quagga/daemons
    sed -i s'/ospfd=no/ospfd=yes/' /etc/quagga/daemons
    echo 'VTYSH_PAGER=more' >>/etc/environment 
    echo 'export VTYSH_PAGER=more' >>/etc/bash.bashrc
    cat >> /etc/quagga/ospfd.conf << EOF
    interface eth1
    interface eth2
    interface lo
    router ospf
     router-id 2.2.2.2
     passive-interface eth1
     network 192.168.3.0/24 area 0.0.0.0
     network 192.168.2.0/24 area 0.0.0.0
    line vty
    EOF
    cat >> /etc/quagga/zebra.conf << EOF
    interface eth1
     ip address 192.168.3.254/24
     ipv6 nd suppress-ra
    interface eth2
     ip address 192.168.2.230/24
     ipv6 nd suppress-ra
    interface lo
    ip forwarding
    line vty
    EOF
    /etc/init.d/quagga start

## Setup routing tables on Client

    ip rule add from 192.168.1.1 table 1
    ip rule add from 192.168.3.1 table 2
    
    ip route add 192.168.1.0/24 dev eth1 scope link table 1
    ip route add default via 192.168.1.254 dev eth1 table 1
    
    ip route add 192.168.3.0/24 dev eth2 scope link table 2
    ip route add default via 192.168.3.254 dev eth2 table 2
    
    ip route add default scope global nexthop via 192.168.1.254 dev eth1

## Setup routing tables on Server

    ip rule add from 192.168.2.1 table 1
    ip rule add from 192.168.2.2 table 2
    
    ip route add 192.168.2.0/24 dev eth1 scope link table 1
    ip route add default via 192.168.2.220 dev eth1 table 1
    
    ip route add 192.168.2.0/24 dev eth2 scope link table 2
    ip route add default via 192.168.2.230 dev eth2 table 2
    
    ip route add default scope global nexthop via 192.168.2.220 dev eth1

