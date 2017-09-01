require 'test_helper'

class RelationshipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    book = nodes(:book)
    book.properties << node_properties(:title)
    book.properties << node_properties(:year)
    book.save!
    author = nodes(:author)
    author.properties << node_properties(:name)
    author.save!
    wrote_rel = relationships(:wrote)
    wrote_rel.to_node = book
    wrote_rel.from_node = author
    wrote_rel.properties << relationship_properties(:role)
    wrote_rel.save!

    @session = Neo4j::Session.open(:server_db, 'http://neo4j-test:7474')
    @session.query('MATCH (n) DETACH DELETE n')
    CypherHelper.session = @session
  end

  test 'should create' do
    author = nodes(:author)
    book = nodes(:book)

    Relationship.destroy_all
    assert_equal 0, Relationship.all.count
    post '/relationships', params: {
      rel_type: 'WROTE',
      to: book.id,
      from: author.id
    }
    res = JSON.parse(@response.body)
    assert_response :created
    assert_equal 1, Relationship.all.count
    assert_equal 'WROTE', res['rel_type']
    assert_equal author.id, res['from_node_id']
    assert_equal book.id, res['to_node_id']
    wrote_rel = Relationship.find_by(rel_type: 'WROTE')
    assert_equal author.id, wrote_rel.from_node.id
    assert_equal book.id, wrote_rel.to_node.id

    author.reload
    book.reload
    assert_equal 1, author.out_relationships.count
    assert_equal 0, author.in_relationships.count
    assert_equal 0, book.out_relationships.count
    assert_equal 1, book.in_relationships.count
    assert_equal wrote_rel.id, author.out_relationships[0].id
    assert_equal wrote_rel.id, book.in_relationships[0].id
    assert_equal 'WROTE', author.out_relationships[0].rel_type
    assert_equal 'WROTE', book.in_relationships[0].rel_type
  end

  test 'should show relationship template' do
    author = nodes(:author)
    book = nodes(:book)
    wrote_rel = relationships(:wrote)

    get '/relationships/' + wrote_rel.id.to_s
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal wrote_rel.id, res['id']
    assert_equal 'WROTE', res['rel_type']
    assert_equal author.id, res['from_node_id']
    assert_equal book.id, res['to_node_id']
  end

  test 'should update relationship template' do
    author = nodes(:author)
    book = nodes(:book)
    wrote_rel = relationships(:wrote)
    # Create Author
    post '/x/author', params: {
      properties: { name: 'Jon' }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Jon', res['properties']['name']
    assert_equal 'author', res['label']
    author_nid = res['nid']
    # Create Book
    post '/x/book', params: {
      properties: {
        title: 'Jungle Book',
        year: 1984
      },
      relationships: {
        in: [
          {
            rel_type: 'WROTE',
            nid: author_nid,
            properties: {
              role: 'lead'
            }
          }
        ]
      } # relationships
    } # params
    assert_response :success

    # Update rel_type
    put '/relationships/' + wrote_rel.id.to_s, params: {
      rel_type: 'COWROTE'
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'COWROTE', res['rel_type']
    assert_equal author.id, res['from_node_id']
    assert_equal book.id, res['to_node_id']
    wrote_rel.reload
    assert_equal 'COWROTE', wrote_rel.rel_type
    # Verify that data was updated to reflect label change
    query = @session.query
                    .match('(n:author)-[r]->(n2:book)')
                    .return(:r).first
    rel = query&.r
    assert_not_nil rel
    assert_equal :COWROTE, rel.rel_type

    # Update property
    put '/relationships/' + wrote_rel.id.to_s, params: {
      properties: {
        role: 'integer'
      }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    res['properties'].each do |property|
      if property['key'] == 'role'
        assert_equal 'integer', property['value_type']
        break
      end
    end
    book.reload
    assert_equal 'integer', wrote_rel.properties.find_by(key: 'role').value_type
    # Verify that data was updated to reflect label change
    query = @session.query
                    .match('(n:author)-[r]->(n2:book)')
                    .return(:r).first
    rel = query&.r
    assert_not_nil rel
    assert_nil rel.props[:role]
  end

  test 'should destroy relationship template' do
    wrote_rel = relationships(:wrote)

    assert_equal 1, Relationship.all.count
    delete '/relationships/' + wrote_rel.id.to_s
    assert_response :success
    assert_equal 0, Relationship.all.count
  end
end
