module CypherHelper
  include TemplateHelper

  @session = if Rails.env.test?
               Neo4j::Session.open(:server_db, 'http://neo4j-test:7474')
             else
               Neo4j::Session.open(:server_db, 'http://neo4j:7474')
             end
  @cypher_str = nil

  # Allow session override for unit tests
  def self.session=(s)
    @session = s
  end

  def self.session
    @session
  end

  def self.get_nodes(node_label)
    @session.query
            .match(n: node_label)
  end

  def self.get_node(nid)
    @session.query
            .match(:n)
            .where('ID(n) = ' + nid)
  end

  def self.search(node_label, properties, prop_types, page)
    query = @session.query
                    .match(n: node_label)
    properties.each do |prop, search_term|
      query_str = 'n.' + prop + ' ='
      query_str += if prop_types[prop] == 'string'
                     "~ '(?i).*" + search_term + ".*'"
                   else
                     ' ' + search_term.to_s
                   end
      query = query.where(query_str)
    end
    query.with(:n)
         .optional_match('(n)-[r]-()')
         .order_by('ID(n)')
         .skip(10 * (page - 1))
         .limit(10)
  end

  def self.create_node(node_label, properties, prop_types)
    # Build CREATE query
    # i.e. `CREATE (n:Person { name: "Johan", from: "Sweden" })`
    cypher_str = '(n:' + node_label + ' {'
    properties.each do |key, value|
      value = TemplateHelper.format_type(value, prop_types[key])
      cypher_str += ' ' + key + ': ' + value + ','
    end
    cypher_str.chomp!(',')
    cypher_str += ' })'

    @session.query.create(cypher_str)
  end

  def self.set_node(nid, properties, prop_types)
    # Build SET query
    # i.e. `SET n.name = 'Taylor'`
    cypher_str = ''
    properties.each do |key, value|
      value = TemplateHelper.format_type(value, prop_types[key])
      cypher_str += 'n.' + key + ' = ' + value + ', '
    end
    cypher_str.chomp!(', ')

    query = @session.query
                    .match(:n)
                    .where('ID(n) = ' + nid)
    properties.empty? ? query : query.set(cypher_str)
  end

  def self.delete_node(nid)
    @session.query
            .match(:n)
            .where('ID(n) = ' + nid)
            .detach_delete(:n)
  end

  def self.remove_node_props(nid, properties)
    # Build REMOVE query
    # i.e. `REMOVE n.name`
    cypher_str = ''
    properties.each do |key|
      cypher_str += 'n.' + key + ', '
    end
    cypher_str.chomp!(', ')

    @session.query
            .match(:n)
            .where('ID(n) = ' + nid)
            .remove(cypher_str)
  end

  # Additive queries (queries that apply to previous queries)

  def self.add_relationships(query)
    query.with(:n).optional_match('(n)-[r]-()')
  end

  def self.add_get_relationship(direction, query, rel_type, nid)
    # Add MATCH query to get r
    # i.e. `(n)-[r:KNOWS]->(n2)`
    match_str = '(n)'
    match_str += '<' if direction == :in
    match_str += '-[r:' + rel_type + ']-'
    match_str += '>' if direction == :out
    match_str += '(n2)'

    query.with(:n)
         .match(match_str)
         .where('ID(n2) = ' + nid.to_s)
  end

  def self.add_create_relationship(direction, query, rel_type, nid, properties,
                                   prop_types)

    # Add relationship to existing CREATE query
    # i.e. `(n)-[:KNOWS {since: 2001}]->(n2)`
    cypher_str = '(n)'
    cypher_str += '<' if direction == :in
    cypher_str += '-[r:' + rel_type
    unless properties.empty?
      cypher_str += ' {'
      properties.each do |key, value|
        value = TemplateHelper.format_type(value, prop_types[key])
        cypher_str += ' ' + key + ': ' + value + ','
      end
      cypher_str.chomp!(',')
      cypher_str += ' }'
    end
    cypher_str += ']-'
    cypher_str += '>' if direction == :out
    cypher_str += '(n2)'

    # Add MATCH to beginning, before CREATE query
    # i.e. `MATCH (n2:Person) WHERE ID(n2) = "1234..." `
    query.match(:n2)
         .where('ID(n2) = ' + nid)
         .create(cypher_str)
  end

  def self.add_set_relationship(direction, query, rel_type, nid, properties,
                                prop_types)

    query = add_get_relationship(direction, query, rel_type, nid)

    # Add relationship to existing SET query
    # i.e. `SET r.role = 'lead'`
    cypher_str = ''
    properties.each do |key, value|
      value = TemplateHelper.format_type(value, prop_types[key])
      cypher_str += 'r.' + key + ' = ' + value + ', '
    end
    cypher_str.chomp!(', ') unless properties.blank?

    query.set(cypher_str)
  end

  def self.add_delete_relationship(direction, query, rel_type, nid)
    query = add_get_relationship(direction, query, rel_type, nid)
    query.delete(:r)
  end

  def self.add_remove_relationship_props(direction, query, rel_type, nid,
                                         properties)
    query = add_get_relationship(direction, query, rel_type, nid)

    # Add remove query
    # i.e. `REMOVE r.role`
    cypher_str = ''
    properties.each do |key|
      cypher_str += 'r.' + key + ', '
    end
    cypher_str.chomp!(', ')

    query.remove(cypher_str)
  end

  # Queries from modification of the templates

  def self.node_query(label)
    @session.query.match(n: label)
  end

  def self.relationship_query(from_label, to_label, rel_type)
    cypher_str = '(n:' + from_label + ')-[r:' + rel_type + ']->(n2:' +
                 to_label + ')'
    @session.query.match(cypher_str)
  end

  def self.add_all_nodes_destroy(query)
    query.delete(:n)
  end

  def self.add_all_rels_destroy(query)
    query.delete(:r)
  end

  def self.add_all_nodes_update_label(query, old_label, new_label)
    query.remove('n:' + old_label)
         .set(n: new_label)
  end

  def self.add_all_nodes_update_prop_type(query, key, _old_type, _new_type)
    # TODO: Convert old values to new values. For now we'll just dispose of the
    # old values.
    query.remove('n.' + key)
  end

  def self.add_all_nodes_remove_prop(query, key)
    query.remove('n.' + key)
  end

  def self.add_all_rels_update_rel_type(query, new_rel_type)
    query.create('(n)-[:' + new_rel_type + ']->(n2)')
         .delete(:r)
  end

  def self.add_all_rels_update_prop_type(query, key, _old_type, _new_type)
    # TODO: Convert old values to new values. For now we'll just dispose of the
    # old values.
    query.remove('r.' + key)
  end

  def self.add_all_rels_remove_prop(query, key)
    query.remove('r.' + key)
  end
end
