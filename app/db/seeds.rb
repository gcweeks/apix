require 'csv'

session = Neo4j::Session.open(:server_db, 'http://neo4j:7474')
session.query('MATCH (n) DETACH DELETE n')

movie_name = NodeProperty.create(key: 'name', value_type: 'string')
movie = Node.new(label: 'movie')
movie.properties << movie_name
movie.save!

director_name = NodeProperty.create(key: 'name', value_type: 'string')
director = Node.new(label: 'director')
director.properties << director_name
director.save!

rel_directed = Relationship.new(rel_type: 'DIRECTED')
rel_directed.from_node = director
rel_directed.to_node = movie
rel_directed.save!

# TODO: Implement
# CSV.foreach('db/movies.csv') do |row|
#   props = {
#     'name' => row[0],
#     'proifle' => row[1],
#     'cover_image' => row[2]
#   }
#   props = TemplateHelper.validate_props(props, movie)
#   prop_types = TemplateHelper.get_prop_types(props, movie)
#   # Start building CREATE query
#   query = CypherHelper.create_node(movie.label, props, prop_types)
#   query.exec
# end
