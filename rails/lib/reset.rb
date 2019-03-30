AbstractNode.all.each(&:destroy) # Nodes and Interfaces
NodeProperty.all.each(&:destroy)
Relationship.all.each(&:destroy)
RelationshipProperty.all.each(&:destroy)
Repo.all.each(&:destroy)
User.all.each(&:destroy)
