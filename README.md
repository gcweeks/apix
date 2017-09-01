# APIX

To setup postgres
```
sudo apt update
sudo apt install postgresql postgresql-contrib libpq-dev
sudo -u postgres createuser -s apix
sudo -u postgres psql
# \password apix
# \q
```
Installing gems
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
Create postgres dbs, migrate schema, and populate with seeds.rb
```
rails db:setup
```
# For Development:
To create from scratch
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
