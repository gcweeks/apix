require 'test_helper'

class NodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:lynx)
    @user.password = 'SecurePa55word'
    @user.generate_token
    @user.save!
    @headers = { 'Authorization' => @user.token }
    @repo = repos(:bookdb)
    @repo.user = @user
    @repo.save!
    @book = nodes(:book)
    @book.repo = @repo
    @book.properties << node_properties(:title)
    @book.properties << node_properties(:year)
    @book.save!
    @author = nodes(:author)
    @author.repo = @repo
    @author.properties << node_properties(:name)
    @author.save!
    wrote_rel = relationships(:wrote)
    wrote_rel.to_node = @book
    wrote_rel.from_node = @author
    wrote_rel.properties << relationship_properties(:role)
    wrote_rel.save!

    @session = Neo4j::Session.open(:server_db, 'http://neo4j-test:7474')
    @session.query('MATCH (n) DETACH DELETE n')
    CypherHelper.session = @session
  end

  test 'should index' do
    assert_equal 2, Node.all.count
    get '/users/' + @user.username + '/repos/' + @repo.name + '/nodes'
    res = JSON.parse(@response.body)
    assert_equal 2, res.count
    get '/users/' + @user.username + '/repos/' + @repo.name + '/nodes', params: { label: 'book' }
    res = JSON.parse(@response.body)
    assert_equal 'book', res['label']
  end

  test 'should create' do
    Node.destroy_all
    assert_equal 0, Node.all.count

    # Requires auth
    post '/users/' + @user.username + '/repos/' + @repo.name + '/nodes', params: {
      label: 'magazine',
      properties: {
        title: 'string',
        years: ['integer'],
        image: {
          details: {
            name: 'string',
            urls: ['string']
          },
          format: 'string'
        },
        related: [{
          image: 'string',
          urls: ['string']
        }]
      }
    }
    assert_response :unauthorized

    # Create template
    post '/users/' + @user.username + '/repos/' + @repo.name + '/nodes', headers: @headers, params: {
      label: 'magazine',
      properties: {
        title: 'string',
        years: ['integer'],
        image: {
          details: {
            name: 'string',
            urls: ['string']
          },
          format: 'string'
        },
        related: [{
          image: 'string',
          urls: ['string']
        }]
      }
    }
    res = JSON.parse(@response.body)
    assert_response :created
    assert_equal 1, Node.all.count
    assert_equal 'magazine', res['label']
    assert_equal 4, res['properties'].count

    magazine = Node.find_by(label: 'magazine')
    assert_equal 'magazine', magazine.label
    assert_equal 4, magazine.properties.count
    title = magazine.properties.find_by(key: 'title')
    assert_equal 'string', title.value_type
    years = magazine.properties.find_by(key: 'years')
    years = eval(years.value_type)
    assert_equal true, years.is_a?(Array)
    assert_equal 1, years.count
    assert_equal 'integer', years[0]
    image = magazine.properties.find_by(key: 'image')
    image = eval(image.value_type)
    assert_equal 'string', image['details']['name']
    assert_equal 1, image['details']['urls'].count
    assert_equal 'string', image['details']['urls'][0]
    assert_equal 'string', image['format']
    related = magazine.properties.find_by(key: 'related')
    related = eval(related.value_type)
    assert_equal 1, related.count
    assert_equal 'string', related[0]['image']
    assert_equal 1, related[0]['urls'].size
    assert_equal 'string', related[0]['urls'][0]
  end

  test 'should show' do
    get '/users/' + @user.username + '/repos/' + @repo.name + '/nodes/' + @book.id.to_s
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal @book.id, res['id']
    assert_equal 'book', res['label']
  end

  test 'should update' do
    # Create Books
    post '/x/' + @user.username + '/' + @repo.name + '/book', params: {
      properties: {
        title: 'Jungle Book',
        year: 1984
      }
    }

    # Requires auth
    put '/users/' + @user.username + '/repos/' + @repo.name + '/nodes/' + @book.id.to_s, params: {
      label: 'novel'
    }
    assert_response :unauthorized

    # Update label
    put '/users/' + @user.username + '/repos/' + @repo.name + '/nodes/' + @book.id.to_s, headers: @headers, params: {
      label: 'novel'
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'novel', res['label']
    @book.reload
    assert_equal 'novel', @book.label
    # Verify that data was updated to reflect label change
    query = @session.query
                    .match(:n)
                    .where(n: { title: 'Jungle Book' })
                    .return(:n).first
    node = query&.n
    assert_not_nil node
    assert_equal 'Jungle Book', node.props[:title]
    label = @user.username.downcase + '/' + @repo.name.downcase + ":novel"
    assert_equal label.to_sym, node.labels[0]

    # Update property
    put '/users/' + @user.username + '/repos/' + @repo.name + '/nodes/' + @book.id.to_s, headers: @headers, params: {
      properties: {
        year: 'string'
      }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    res['properties'].each do |property|
      if property['key'] == 'year'
        assert_equal 'string', property['value_type']
        break
      end
    end
    @book.reload
    assert_equal 'string', @book.properties.find_by(key: 'year').value_type
    # Verify that data was updated to reflect label change
    query = @session.query
                    .match(:n)
                    .where(n: { title: 'Jungle Book' })
                    .return(:n).first
    node = query&.n
    assert_not_nil node
    # TODO: Eventually expect for property to be converted
    # assert_equal '1984', node.props[:year]
    assert_nil node.props[:year]
  end

  test 'should destroy' do
    assert_equal 2, Node.all.count

    # Requires auth
    delete '/users/' + @user.username + '/repos/' + @repo.name + '/nodes/' + @book.id.to_s
    assert_response :unauthorized

    delete '/users/' + @user.username + '/repos/' + @repo.name + '/nodes/' + @book.id.to_s, headers: @headers
    assert_response :success
    assert_equal 1, Node.all.count
    assert_equal @author.id, Node.all[0].id
  end
end
