# Description

This Docker image helps you forward ports of containers to remote servers.
If you publish the forwarded ports of a container, you can use it to forward your local ports to the remote server through the container.
Sometimes the previous way is undesired, since you want to keep the local ports free.
In this case you should keep /etc/hosts up to date even if the ip addresses of the containers can be changed. This can be solved using [rimelek/hosts-gen](https://hub.docker.com/r/rimelek/hosts-gen/) and [rimelek/hosts-updater](https://hub.docker.com/r/rimelek/hosts-updater/).
With the help of these images you can have a VPN-like solution. So you can even mount a samba drive from a remote private network.

First of all you have to copy your SSH public key to each server you want to ssh. 

The simplest example when a local port is forwarded to a remote server's local port. For instance, you have a remote web server with a virtual host accessible only from localhost or a MySQL server which is not published.

    version: "2"
    
    services:
      remote-mysql:
        image: rimelek/ssh-tunnel
        volumes:
          - "${HOME}/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub"
          - "${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa"
        environment:
          VIRTUAL_HOST: remote-mysql
          TUNNEL_HOST: user@remotehost:2200
          TUNNEL_REMOTES: "127.0.0.1:3306"
          
In the above example the container's port 3306 is forwarded remotehost's local port 3306 via SSH tunnel through the port 2200.
If you use the mentioned rimelek/hosts-gen and the updater, you will be able to access to the remote mysql using "remote-mysql" as host name.

The other case when you have a web server inside a remote private network and you wish to access it from the local machine.

    version: "2"
    
    services:
      remote-web:
        image: rimelek/ssh-tunnel
        volumes:
          - "${HOME}/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub"
          - "${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa"
        environment:
          VIRTUAL_HOST: first.remote.host,second.remote.host
          TUNNEL_HOST: user@remotehost:2200
          TUNNEL_REMOTES: |
            first.remote.host:443
            second.remote.host:443
            second.remote.host:80
            
The "|" (pipe) character allows you to set a multiline text to a variable. If you have multiple host on the remote server, you can list them line by line. Each line is a host and port separated by colon.

There is a trickier way to use the SSH tunnel. If you forward the SSH port of a container to a remote SSH port, you can tunnel an other container's port through that. This way you can access a server's local port inside a remote private network which is inaccessible directly via SSH.

    version: "2"
    
    services:
      privatemysql-ssh:
        image: rimelek/ssh-tunnel
        volumes:
          - "${HOME}/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub"
          - "${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa"
        environment:
          TUNNEL_HOST: user@publichost:2200
          TUNNEL_REMOTES: "mysql.private.lan:22"
        expose:
          - 22
      privatemysql:
        image: rimelek/ssh-tunnel
        volumes:
          - "${HOME}/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub"
          - "${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa"
        links:
          - privatemysql-ssh
        environment:
          VIRTUAL_HOST: mysql.private.lan
          TUNNEL_HOST: user@privatemysql-ssh:22
          TUNNEL_REMOTES: "127.0.0.1:3306"
          
Now mysql.private.lan is accessible on port 3306 from your local machine.

As I mentioned at the top of the README, this image is can be used to mount a private samba drive.

    version: "2"
    
    services:
      privatesamba:
        image: rimelek/ssh-tunnel
        volumes:
          - "${HOME}/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub"
          - "${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa"
        environment:
          VIRTUAL_HOST: privatesamba
          TUNNEL_REMOTES: |
            samba.private.lan:137
            samba.private.lan:138
            samba.private.lan:139
            samba.private.lan:445

Here every ports used by a samba server are forwarded to the private samba server. Now type the following in a file browser's address bar:

   smb://privatesamba/sharedfolder

I assume you have many different private server. You can shorten the definitions by inheriting one container's definition:


    version: "2"
    
    services:
      publicserver:
        image: rimelek/ssh-tunnel
        volumes:
          - "${HOME}/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub"
          - "${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa"
        environment:
          TUNNEL_HOST: user@publichost:2200
          TUNNEL_REMOTES: "127.0.0.1:2200"
      privatemysql-ssh:
        extends:
          service: publicserver
        environment:
          TUNNEL_HOST: user@publichost:2200
          TUNNEL_REMOTES: "mysql.private.lan:22"
        expose:
          - 22
      privatemysql:
        extends:
          service: publicserver
        links:
          - privatemysql-ssh
        environment:
          VIRTUAL_HOST: mysql.private.lan
          TUNNEL_HOST: user@privatemysql-ssh:22
          TUNNEL_REMOTES: "127.0.0.1:3306"
      privatesamba:
        extends:
          service: publicserver
        environment:
          VIRTUAL_HOST: privatesamba
          TUNNEL_REMOTES: |
            samba.private.lan:137
            samba.private.lan:138
            samba.private.lan:139
            samba.private.lan:445
      privateweb:
        extends:
          service: publicserver
        environment:
          VIRTUAL_HOST: web.private.lan
          TUNNEL_REMOTES: |
            web1.private.lan:443
            web2.private.lan:443
            web2.private.lan:80
            
In the above case the first container's definition is the base of the others. You need to redefine only the differences.

As you can see it is not so far from a VPN. You have to define more manually, but you get more control over the network. Your local private network and some ports of some remote machines from the remote network will be available at the same time. And this is more than a simple SSH tunnel, since your local ports will be untouched if you want.