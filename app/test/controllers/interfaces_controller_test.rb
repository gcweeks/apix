require 'test_helper'

class InterfacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:lynx)
    @user.password = 'SecurePa55word'
    @user.generate_token
    @user.save!
    @headers = { 'Authorization' => @user.token }
    @repo = repos(:bookdb)
    @repo.user = @user
    @repo.save!
    @person = interfaces(:person)
    @person.repo = @repo
    @person.properties << node_properties(:name)
    @person.save!
  end

  test 'should index' do
    assert_equal 1, Interface.all.count
    get '/users/' + @user.username + '/repos/' + @repo.name + '/interfaces'
    res = JSON.parse(@response.body)
    assert_equal 1, res.count
    get '/users/' + @user.username + '/repos/' + @repo.name + '/interfaces', params: { label: 'person' }
    res = JSON.parse(@response.body)
    assert_equal 'person', res['label']
  end

  test 'should create' do
    Interface.destroy_all
    assert_equal 0, Interface.all.count

    # Requires auth
    post '/users/' + @user.username + '/repos/' + @repo.name + '/interfaces', params: {
      label: 'article',
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
    post '/users/' + @user.username + '/repos/' + @repo.name + '/interfaces', headers: @headers, params: {
      label: 'article',
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
    assert_equal 1, Interface.all.count
    assert_equal 'article', res['label']
    assert_equal 4, res['properties'].count

    article = Interface.find_by(label: 'article')
    assert_equal 'article', article.label
    assert_equal 4, article.properties.count
    title = article.properties.find_by(key: 'title')
    assert_equal 'string', title.value_type
    years = article.properties.find_by(key: 'years')
    years = eval(years.value_type)
    assert_equal true, years.is_a?(Array)
    assert_equal 1, years.count
    assert_equal 'integer', years[0]
    image = article.properties.find_by(key: 'image')
    image = eval(image.value_type)
    assert_equal 'string', image['details']['name']
    assert_equal 1, image['details']['urls'].count
    assert_equal 'string', image['details']['urls'][0]
    assert_equal 'string', image['format']
    related = article.properties.find_by(key: 'related')
    related = eval(related.value_type)
    assert_equal 1, related.count
    assert_equal 'string', related[0]['image']
    assert_equal 1, related[0]['urls'].size
    assert_equal 'string', related[0]['urls'][0]
  end

  test 'should show' do
    get '/users/' + @user.username + '/repos/' + @repo.name + '/interfaces/' + @person.id.to_s
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal @person.id, res['id']
    assert_equal 'person', res['label']
  end

  test 'should update' do
    # Requires auth
    put '/users/' + @user.username + '/repos/' + @repo.name + '/interfaces/' + @person.id.to_s, params: {
      label: 'novel'
    }
    assert_response :unauthorized

    # Update label
    put '/users/' + @user.username + '/repos/' + @repo.name + '/interfaces/' + @person.id.to_s, headers: @headers, params: {
      label: 'novel'
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'novel', res['label']
    @person.reload
    assert_equal 'novel', @person.label

    # Update property
    put '/users/' + @user.username + '/repos/' + @repo.name + '/interfaces/' + @person.id.to_s, headers: @headers, params: {
      properties: {
        name: 'integer'
      }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    res['properties'].each do |property|
      if property['key'] == 'name'
        assert_equal 'integer', property['value_type']
        break
      end
    end
    @person.reload
    assert_equal 'integer', @person.properties.find_by(key: 'name').value_type
  end

  test 'should destroy' do
    assert_equal 1, Interface.all.count

    # Requires auth
    delete '/users/' + @user.username + '/repos/' + @repo.name + '/interfaces/' + @person.id.to_s
    assert_response :unauthorized

    delete '/users/' + @user.username + '/repos/' + @repo.name + '/interfaces/' + @person.id.to_s, headers: @headers
    assert_response :success
    assert_equal 0, Interface.all.count
  end
end
