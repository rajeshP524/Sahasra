#!/bin/bash

set -x
DEVICE=$( ip addr show | grep -w 'inet 182.17' | awk '{print $7}' )
MY_MACADDR=$( ip addr show ${DEVICE} | grep -Po 'link/ether \K[\da-f:]+' )
MY_IP=$( ip -br a | awk '{print $3}' | cut -d"/" -f1 | grep 182 )
WRITE_CONF="/write_config.py -e container_ip=${MY_IP}"

cat /hosts >> /etc/hosts

pushd /etc/nova
${WRITE_CONF} nova.conf.fragment /nova.conf nova.conf
popd

pushd /etc/neutron
${WRITE_CONF} neutron.conf.fragment /neutron.conf neutron.conf
${WRITE_CONF} openvswitch_agent.ini.fragment /openvswitch_agent.ini plugins/ml2/openvswitch_agent.ini
popd

systemctl enable openstack-nova-compute.service
systemctl start openstack-nova-compute.service

systemctl enable neutron-openvswitch-agent.service
systemctl start neutron-openvswitch-agent.service

#ovs
ovsdb-server /etc/openvswitch/conf.db -vconsole:emer -vsyslog:err -vfile:info --remote "ptcp:6640:127.0.0.1" --remote=punix:/var/run/openvswitch/db.sock --private-key=db:Open_vSwitch,SSL,private_key --certificate=db:Open_vSwitch,SSL,certificate --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert --user openvswitch:hugetlbfs --no-chdir --log-file=/var/log/openvswitch/ovsdb-server.log --pidfile=/var/run/openvswitch/ovsdb-server.pid --detach
# ovs-vsctl set-manager "ptcp:6640:127.0.0.1"
ovs-vswitchd unix:/var/run/openvswitch/db.sock -vconsole:emer -vsyslog:err -vfile:info --mlockall --user openvswitch:hugetlbfs --no-chdir --log-file=/var/log/openvswitch/ovs-vswitchd.log --pidfile=/var/run/openvswitch/ovs-vswitchd.pid --detach

# TODO: ip address on the bridge?
ovs-vsctl -t 10 -- --may-exist add-br br-ex -- set bridge br-ex other-config:hwaddr=${MY_MACADDR} -- set bridge br-ex fail_mode=standalone -- del-controller br-ex

$(command -v python3 || command -v python) -m neutron.cmd.destroy_patch_ports --config-file /usr/share/neutron/neutron-dist.conf --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/openvswitch_agent.ini --config-dir /etc/neutron/conf.d/common --config-dir /etc/neutron/conf.d/neutron-openvswitch-agent &
/usr/bin/neutron-openvswitch-agent --config-file /usr/share/neutron/neutron-dist.conf --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/openvswitch_agent.ini --config-dir /etc/neutron/conf.d/common --log-file=/var/log/neutron/openvswitch-agent.log &
