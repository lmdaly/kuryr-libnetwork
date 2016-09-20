===============================
kuryr-libnetwork
===============================

.. image:: https://raw.githubusercontent.com/openstack/kuryr/master/doc/images/kuryr_logo.png
    :alt: Kuryr mascot
    :align: center


Docker for OpenStack Neutron

Kuryr-libnetwork is `Kuryr's <https://github.com/openstack/kuryr>`_ Docker
libnetwork driver that uses Neutron to provide networking services. It provides
containerised images for the common Neutron plugins.

This repo provides libnetwork specific functionalities such as handler methods
for libnetwork apis. All the logic/utilities that can be shared among
different container networking frameworks such as Docker's libnetwork,
K8s's CNI and so on, is maintained in separate Kuryr repo as a common library.


* Free software: Apache license
* Documentation: http://docs.openstack.org/developer/kuryr-libnetwork
* Source: http://git.openstack.org/cgit/openstack/kuryr-libnetwork
* Bugs: http://bugs.launchpad.net/kuryr-libnetwork

Features
--------

* Docker libnetwork remote driver

* Docker libnetwork IPAM driver

* Support for Linux Bridge, Open vSwitch, Midonet, and IOvisor port bindings

* Support for using existing Neutron networks::

    docker network create -d kuryr --ipam-driver=kuryr --subnet=10.10.0.0/24 --gateway=10.10.0.1 \
       -o neutron.net.uuid=d98d1259-03d1-4b45-9b86-b039cba1d90d mynet

    docker network create -d kuryr --ipam-driver=kuryr --subnet=10.10.0.0/24 --gateway=10.10.0.1 \
       -o neutron.net.name=my_neutron_net mynet

* Support for using existing Neutron ports::

    docker run -it --net=kuryr_net --ip=10.0.0.5 ubuntu

    if a port in the corresponding subnet with the requested ip address
    already exists and it is unbound, that port is used for the
    container.

* Support for the Docker "expose" option::

    docker run --net=my_kuryr_net --expose=1234-1238/udp -it ubuntu

    This feature is implemented by using Neutron security groups.

Limitations
-----------

* Docker 1.12 with SwarmKit (the new Swarm) does not support remote
  drivers. Therefore, it cannot be used with Kuryr. This limitation is
  to be removed in Docker 1.13.

Getting it running with a service container
-------------------------------------------

Prerequisites
~~~~~~~~~~~~~

The necessary components for an operating environment to run Kuryr are:

* Keystone (preferably configured with Keystone v3),
* Neutron (preferably mitaka or newer),
* DB management system suh as MySQL or Mariadb (for Neutron and Keystone),
* Neutron agents for the vendor you choose,
* Rabbitmq if the Neutron agents for your vendor require it,
* Docker 1.9+

Building the container
~~~~~~~~~~~~~~~~~~~~~~

The Dockerfile in the root of this repository can be used to generate a wsgi
Kuryr Libnetwork server container with docker build::

    docker build -t your_docker_username/libnetwork:latest .

Additionally, you can pull the upstream container::

    docker pull kuryr/libnetwork:latest

Note that you can also specify the tag of a stable release for the above
command instead of *latest*.

How to run the container
~~~~~~~~~~~~~~~~~~~~~~~~

First we prepare Docker to find the driver::

    sudo mkdir -p /usr/lib/docker/plugins/kuryr
    sudo curl -o /usr/lib/docker/plugins/kuryr/kuryr.spec \
    https://raw.githubusercontent.com/openstack/kuryr-libnetwork/master/etc/kuryr.spec
    sudo service docker restart

Then we start the container::

    docker run --name kuryr-libnetwork \
      --net=host \
      --cap-add=NET_ADMIN \
      -e SERVICE_USER=admin \
      -e SERVICE_PROJECT_NAME=admin \
      -e SERVICE_PASSWORD=admin \
      -e SERVICE_DOMAIN_NAME=Default \
      -e USER_DOMAIN_NAME=Default \
      -e IDENTITY_URL=http://127.0.0.1:35357/v3 \
      -v /var/log/kuryr:/var/log/kuryr \
      -v /var/run/openvswitch:/var/run/openvswitch \
      kuryr/libnetwork

Where:
* SERVICE_USER, SERVICE_PROJECT_NAME, SERVICE_PASSWORD, SERVICE_DOMAIN_NAME,
USER_DOMAIN_NAME are OpenStack credentials
* IDENTITY_URL is the url to the OpenStack Keystone v3 endpoint
* A volume is created so that the logs are available on the host
* NET_ADMIN capabilities are given in order to perform network operations on
the host namespace like ovs-vsctl

Other options you can set as '-e' parameters in Docker run:
* CAPABILITY_SCOPE can be "local" or "global", the latter being for when there
is a cluster store plugged into the docker engine.
* LOG_LEVEL for defining, for example, "DEBUG" logging messages.
* PROCESSES for defining how many kuryr processes to use to handle the
libnetwork requests.
* THREADS for defining how many threads per process to use to handle the
libnetwork requests.

Note that you will probably have to change the 127.0.0.1 IDENTITY_URL address
for the address where your Keystone is running. In this case it is 127.0.0.1
because the example assumes running the container with *--net=host* on an all
in one deployment where Keystone is also binding locally.

Alternatively, if you have an existing kuryr.conf, you can use it for the
container::

    docker run --name kuryr-libnetwork \
      --net host \
      --cap-add NET_ADMIN \
      -v /etc/kuryr:/etc/kuryr:ro \
      -v /var/log/kuryr:/var/log/kuryr:rw \
      -v /var/run/openvswitch:/var/run/openvswitch:rw \
      kuryr/libnetwork


Getting it from source
----------------------

::

    $ git clone https://git.openstack.org/openstack/kuryr-libnetwork
    $ cd kuryr-libnetwork


Prerequisites
~~~~~~~~~~~~~

::

    $ sudo pip install -r requirements.txt


Installing Kuryr's libnetwork driver
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Running the following will grab the requirements and install kuryr::

    $ sudo pip install .


Configuring Kuryr
~~~~~~~~~~~~~~~~~

Generate sample config, `etc/kuryr.conf.sample`, running the following::

    $ ./tools/generate_config_file_samples.sh


Rename and copy config file at required path::

    $ cp etc/kuryr.conf.sample /etc/kuryr/kuryr.conf


For using Keystone v3, edit the Neutron section in `/etc/kuryr/kuryr.conf`, replace ADMIN_PASSWORD::

    [neutron]
    auth_url = http://127.0.0.1:35357/v3/
    username = admin
    user_domain_name = Default
    password = ADMIN_PASSWORD
    project_name = service
    project_domain_name = Default
    auth_type = password


Alternatively, for using Keystone v2, edit the Neutron section in `/etc/kuryr/kuryr.conf`, replace ADMIN_PASSWORD::

    [neutron]
    auth_url = http://127.0.0.1:35357/v2.0/
    username = admin
    password = ADMIN_PASSWORD
    project_name = service
    auth_type = password


In the same file uncomment the `bindir` parameter with the path for the Kuryr
vif binding executables. For example, if you installed it on Debian or Ubuntu::

    [DEFAULT]
    bindir = /usr/local/libexec/kuryr


Running Kuryr
~~~~~~~~~~~~~

Currently, Kuryr utilizes a bash script to start the service. Make sure that
you have installed `tox` before the execution of the command below::

    $ sudo ./scripts/run_kuryr.sh

After Kuryr starts, please restart your Docker service, e.g.::

    $ sudo service docker restart

The bash script creates the following file if it is missing:

* ``/usr/lib/docker/plugins/kuryr/kuryr.json``: Json spec file for libnetwork.

Note the root privilege is required for creating and deleting the veth pairs
with `pyroute2 <http://docs.pyroute2.org/>`_ to run.

Testing Kuryr
-------------

For a quick check that Kuryr is working, create a network::

    $ docker network create --driver kuryr --ipam-driver kuryr \
    --subnet 10.10.0.0/16 test_net
    785f8c1b5ae480c4ebcb54c1c48ab875754e4680d915b270279e4f6a1aa52283
    $ docker network ls
    NETWORK ID          NAME                DRIVER
    785f8c1b5ae4        test_net            kuryr

To test it with tox::

    $ tox

You can also run specific test cases using the ``-e`` flag, e.g., to only run
the *fullstack* test case::

    $ tox -e fullstack

Generating Documentation
------------------------


We use `Sphinx <https://pypi.python.org/pypi/Sphinx>`_ to maintain the
documentation. You can install Sphinx using pip::

    $ pip install -U Sphinx

In addition to Sphinx you will also need the following requirements
(not covered by `requirements.txt`)::

    $ pip install oslosphinx reno 'reno[sphinx]'

The source code of the documentation are under *doc*, you can generate the
html files using the following command. If the generation succeeds,a
*build/html* dir will be created under *doc*::

    $ cd doc
    $ make html

Now you can serve the documentation at http://localhost:8080 as a simple
website::

    $ cd build/html
    $ python -m SimpleHTTPServer 8080

Limitations
-----------

To create Docker networks with subnets having same/overlapping cidr, it is
expected to pass unique pool name for each such network creation Docker
command. Docker cli options -o and --ipam-opt should be used to pass pool
names as shown below::

    $ sudo docker network create --driver=kuryr --ipam-driver=kuryr \
      --subnet 10.0.0.0/16 --ip-range 10.0.0.0/24 \
      -o neutron.pool.name=neutron_pool1 \
      --ipam-opt=neutron.pool.name=neutron_pool1 \
      foo
      eddb51ebca09339cb17aaec05e48ffe60659ced6f3fc41b020b0eb506d364

Now Docker user creates another network with same cidr as the previous one,
i.e 10.0.0.0/16, but with different pool name, neutron_pool2::

    $ sudo docker network create --driver=kuryr --ipam-driver=kuryr \
      --subnet 10.0.0.0/16 --ip-range 10.0.0.0/24 \
      -o neutron.pool.name=neutron_pool2 \
      --ipam-opt=neutron.pool.name=neutron_pool2 \
      bar
      397badb51ebca09339cb17aaec05e48ffe60659ced6f3fc41b020b0eb506d786


External Resources
------------------

The latest and most in-depth documentation is available at:
    <https://github.com/openstack/kuryr/tree/master/doc/source>
