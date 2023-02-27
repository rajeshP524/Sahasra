FROM registry.access.redhat.com/ubi8/ubi:8.4

COPY ./rhos-release-16.2.repo /etc/yum.repos.d/
COPY ./rhos-release-rhel-8.4.repo /etc/yum.repos.d/
COPY ./entrypoint.sh /

RUN yum install kernel-modules-4.18.0-193.el8.x86_64 -y
RUN yum install openstack-neutron-openvswitch -y
RUN yum install openstack-nova-compute -y

COPY ./nova.conf.fragment /etc/nova/
COPY ./neutron.conf.fragment /etc/neutron/
COPY ./openvswitch_agent.ini.fragment /etc/neutron/
COPY ./hosts /
COPY ./openvswitch_agent.ini /
COPY ./neutron.conf /
COPY ./nova.conf /
COPY ./write_config.py /write_config.py
COPY ./neutron-enable-bridge-firewall.sh /usr/bin/neutron-enable-bridge-firewall.sh

RUN chmod 777 /usr/bin/neutron-enable-bridge-firewall.sh

RUN pip3 install fixtures
RUN cp /usr/bin/python3 /usr/bin/python
RUN chmod 0775 /entrypoint.sh

CMD ["/usr/sbin/init"]
