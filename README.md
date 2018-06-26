# APIX

This repository is structured as follows:

* **app/** - The Apix Rails app
* **git/** - Files for server git setup
* **nginx/** - Files for server nginx setup
* **preload-images/** - Cached Vagrant image files
* **docker-compose.prod.yml** - Compose file for production server
* **docker-compose.test.yml** - Compose file for running unit tests
* **docker-compose.yml** - Compose file for just the app
* **Dockerfile** - For Rails container
* **dump.sh** - Script for dumping Postgres/Neo4j DBs
* **environment** - Contains server env variables
* **restore.sh** - Script for restoring Postgres/Neo4j DBs
* **setup.sh** - Server setup instructions and script
* **test.sh** - Runs unit tests with docker-compose
* **Vagrantfile** - Loads app in boot2docker VM

There are two ways to setup the application: Using **Vagrant** and the provided Vagrant files (recommended), or **manually** by setting up your local environment with everything needed to run the app including Rails, Postgres, and Neo4j.

## Vagrant

Install the following tools:

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/)

With Vagrant installed, all you need to do is run:

```
vagrant up
```

This will download all the necessary dependencies like VMs and Docker containers, so sit back and wait for everything to download. Once that has completed, Vagrant will report the following:

```
Server running at 192.168.12.34
To ssh into the box:

   vagrant ssh
   tcuser
   cd /vagrant
```

Check `192.168.12.34` in a browser or with cURL to verify that the server has loaded (at this point it will just return a version number).

As the prompt says, you can ssh into the Vagrant VM (the machine running the docker containers containing the app components) using the following command:

```vagrant ssh```

If you are restoring the VM from a `vagrant halt` rather than running it for the first, the VM will prompt you for a password, which is `tcuser` (as listed at the end of the `vagrant up` output). Once logged in, change to the `/vagrant` directory and you will find all of the server files mapped from the host.

Server files can also be modified outside of Vagrant. To modify any of the server files, simply make the local modifications and Rails should automatically pick up the changes. If Rails doesn't pick up a change (i.e. a lower-level changes that requires a server restart), you can reload the Vagrant environment at any time using:

```vagrant reload```

When you're ready to stop the server, type:

```vagrant halt```

## Manual Method (Ubuntu)

If you don't want to use Vagrant, you can set up your local environment with everything needed to run the app including Rails, Postgres, and Neo4j.

To setup Java

```
sudo apt install openjdk-8-jdk
```

To setup Postgres

```
sudo apt update
sudo apt install postgresql postgresql-contrib libpq-dev
sudo -u postgres createuser -s apix
sudo -u postgres psql
# \password apix
# \q
```

To install gems

```
bundle
```

To setup Neo4j

```
rails neo4j:install[community-latest,development]
rails neo4j:start[development]
# Install test as well, using port 7575 rather than 7474
rails neo4j:install[community-latest,test]
rails neo4j:config[test,7575]
rails neo4j:start[test]
```

Set all hostnames to localhost by adding the following to your `/etc/hosts` file:

```
127.0.0.1       postgres
127.0.0.1       neo4j
127.0.0.1       neo4j-test
```

Create postgres dbs, migrate schema, and populate with seeds.rb

```
rails db:setup
```

### For Development:
To create the rails app from scratch

```
rails new apix --api -m http://neo4jrb.io/neo4j/neo4j.rb -O
```

Generating a model with ActiveRecord (SQL) rather than Neo4j

```
rails g active_record:model mymodel
```

Resetting databases

```
rails db:reset
rails neo4j:reset_yes_i_am_sure[development]
```
