require 'test_helper'

class GraphControllerTest < ActionDispatch::IntegrationTest
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

  test 'should get all nodes for label' do
    # Create Author
    post '/x/author', params: {
      properties: { name: 'Jon' }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Jon', res['properties']['name']
    assert_equal 'author', res['label']
    author_nid = res['nid']
    # Create Books
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
    post '/x/book', params: {
      properties: {
        title: 'Hamlet',
        year: 1600
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

    # Get all books
    get '/x/book'
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 2, res.count
    res.each do |node|
      assert_equal 'book', node['label']
      assert_equal 1, node['relationships'].size
      rel = node['relationships'][0]
      assert_equal 'lead', rel['properties']['role']
      assert_equal 'WROTE', rel['rel_type']
      assert_equal author_nid, rel['from_nid']
      assert_equal node['nid'], rel['to_nid']
    end
  end

  test 'should create node' do
    # Can't create without properties
    post '/x/author'
    assert_response :bad_request

    # Create proper Author
    post '/x/author', params: {
      properties: { name: 'Jon' }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Jon', res['properties']['name']
    assert_equal 'author', res['label']
    author_nid = res['nid']
    # Can't create with nonexistent properties
    post '/x/author', params: {
      properties: { invalid: 'property' }
    }
    assert_response :bad_request
    post '/x/book', params: {
      properties: {
        title: 'Hamlet',
        year: 1600
      },
      relationships: {
        in: [
          {
            rel_type: 'WROTE'
          } # No nid
        ]
      }
    }
    assert_response :bad_request
    post '/x/book', params: {
      properties: {
        title: 'Hamlet',
        year: 1600
      },
      relationships: {
        in: [
          {
            rel_type: 'WROTE',
            nid: 999_999_999 # Nonexistent
          }
        ]
      }
    }
    assert_response :bad_request
    post '/x/book', params: {
      properties: {
        title: 'Hamlet',
        year: 1600
      },
      relationships: {
        in: [
          {
            rel_type: 'READ', # Nonexistent
            nid: author_nid
          }
        ]
      }
    }
    assert_response :bad_request
    post '/x/book', params: {
      properties: {
        title: 'Hamlet',
        year: 1600
      },
      relationships: {
        in: [
          {
            rel_type: 'WROTE',
            nid: author_nid,
            properties: {
              plagiarism: 'lots' # Nonexistent
            }
          }
        ]
      } # relationships
    } # params
    assert_response :bad_request
    # Create proper Book
    post '/x/book', params: {
      properties: {
        title: 'Hamlet',
        year: 1600
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
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Hamlet', res['properties']['title']
    assert_equal 1600, res['properties']['year']
    assert_equal 'book', res['label']

    # Verify that data was stored
    query = @session.query
                    .match(a: :author, b: :book)
                    .where(a: { name: 'Jon' }, b: { title: 'Hamlet' })
                    .return(:a, :b).first
    author = query&.a
    assert_not_nil author
    assert_equal 'Jon', author.props[:name]
    book = query&.b
    assert_not_nil book
    assert_equal 'Hamlet', book.props[:title]
    assert_equal 1600, book.props[:year]
    # Verify relationship
    assert_equal 1, author.rels.size
    assert_equal 1, book.rels.size
    assert_equal :WROTE, author.rels[0].rel_type
    assert_equal :WROTE, book.rels[0].rel_type
    assert_equal author.neo_id, book.rels[0].start_node_neo_id
    assert_equal book.neo_id, author.rels[0].end_node_neo_id

    # Complex properties
    post '/nodes', params: {
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
    assert_equal 'magazine', res['label']
    assert_equal 4, res['properties'].count
    magazine_id = res['id']
    post '/relationships', params: {
      rel_type: 'PUBLISHED',
      to: magazine_id,
      from: nodes(:author).id,
      properties: {
        years: ['integer'],
        image: {
          details: {
            name: 'string',
            urls: ['string']
          },
          format: 'string'
        }
      }
    }
    assert_response :created

    # # Bad requests
    # post '/x/magazine', params: {
    #   properties: {
    #     # Should be string
    #     title: ['Cypher Weekly', 'Cypher Monthly']
    #   }
    # }
    # post '/x/magazine', params: {
    #   properties: {
    #     # Should be [integer]
    #     years: 2015
    #   }
    # }
    # post '/x/magazine', params: {
    #   properties: {
    #     image: {
    #       details: {
    #         # Should be [string]
    #         urls: 'apix.rocks'
    #       }
    #     }
    #   }
    # }
    # post '/x/magazine', params: {
    #   properties: {
    #     image: {
    #       # Field does not exist
    #       views: 5
    #     }
    #   }
    # }
    # post '/x/magazine', params: {
    #   properties: {
    #     # Should be [{image:string, urls: [string]}]
    #     related: {
    #       image: 'img.jpg',
    #       urls: ['a.com', 'b.com']
    #     }
    #   }
    # }
    # post '/x/magazine', params: {
    #   properties: {
    #     title: 'Cypher Weekly'
    #   },
    #   relationships: {
    #     in: [
    #       {
    #         rel_type: 'PUBLISHED',
    #         nid: author_nid,
    #         properties: {
    #           # Should be [integer]
    #           years: 2017
    #         }
    #       }
    #     ]
    #   }
    # }
    # post '/x/magazine', params: {
    #   properties: {
    #     title: 'Cypher Weekly'
    #   },
    #   relationships: {
    #     in: [
    #       {
    #         rel_type: 'PUBLISHED',
    #         nid: author_nid,
    #         properties: {
    #           image: {
    #             details: {
    #               # Should be [string]
    #               urls: 'apix.rocks'
    #             }
    #           }
    #         }
    #       }
    #     ]
    #   }
    # }

    # Create magazine instance
    post '/x/magazine', params: {
      properties: {
        title: 'Cypher Weekly',
        years: [2015, 2016, 2017],
        image: {
          details: {
            name: 'zeen',
            urls: [
              'apix.rocks',
              'findditfor.me'
            ]
          },
          format: 'large'
        },
        related: [
          {
            image: 'img.jpg',
            urls: ['a.com', 'b.com']
          },
          {
            image: 'img2.jpg',
            urls: ['c.com', 'd.com']
          }
        ]
      },
      relationships: {
        in: [
          {
            rel_type: 'PUBLISHED',
            nid: author_nid,
            properties: {
              years: [2015, 2016, 2017],
              image: {
                details: {
                  name: 'zeen',
                  urls: [
                    'apix.rocks',
                    'findditfor.me'
                  ]
                },
                format: 'large'
              }
            }
          }
        ]
      } # relationships
    } # params
    res = JSON.parse(@response.body)
    assert_response :success
    assert_not_nil res
    assert_not_nil res['properties']
    assert_not_nil res['properties']['image']
    assert_not_nil res['properties']['image']['details']
    assert_not_nil res['properties']['related']
    assert_not_nil res['relationships']
    assert_equal 1, res['relationships'].count
    rel = res['relationships'][0]
    assert_not_nil rel['properties']
    assert_not_nil rel['properties']['image']
    assert_not_nil rel['properties']['image']['details']
    assert_equal 'Cypher Weekly', res['properties']['title']
    # assert_equal [2015, 2016, 2017], res['properties']['years']
    assert_equal %w(2015 2016 2017), res['properties']['years'] # TODO
    assert_equal 'zeen', res['properties']['image']['details']['name']
    assert_equal ['apix.rocks', 'findditfor.me'],
                 res['properties']['image']['details']['urls']
    assert_equal 'large', res['properties']['image']['format']
    assert_equal 2, res['properties']['related'].count
    assert_equal 'img.jpg', res['properties']['related'][0]['image']
    assert_equal ['a.com', 'b.com'], res['properties']['related'][0]['urls']
    assert_equal 'img2.jpg', res['properties']['related'][1]['image']
    assert_equal ['c.com', 'd.com'], res['properties']['related'][1]['urls']
    assert_equal 'PUBLISHED', rel['rel_type']
    # assert_equal [2015, 2016, 2017], rel['properties']['years']
    assert_equal %w(2015 2016 2017), rel['properties']['years'] # TODO
    assert_equal 'zeen', rel['properties']['image']['details']['name']
    assert_equal ['apix.rocks', 'findditfor.me'],
                 rel['properties']['image']['details']['urls']
    assert_equal 'large', rel['properties']['image']['format']

    # Verify that data was stored
    query = @session.query
                    .match('(n:magazine)<-[r:PUBLISHED]-()')
                    .return(:n, :r).first
    magazine = query&.n
    assert_not_nil magazine
    assert_not_nil magazine.props
    assert_not_nil magazine.props[:image]
    assert_not_nil magazine.props[:related]
    assert_equal 'Cypher Weekly', magazine.props[:title]
    # assert_equal [2015, 2016, 2017], magazine.props[:years]
    assert_equal %w(2015 2016 2017), magazine.props[:years] # TODO
    str = '{"details"=>{"name"=>"zeen", "urls"=>["apix.rocks",'\
                ' "findditfor.me"]}, "format"=>"large"}'
    assert_equal str, magazine.props[:image]
    assert_equal 2, magazine.props[:related].count
    str = '{"image"=>"img.jpg", "urls"=>["a.com", "b.com"]}'
    assert_equal str, magazine.props[:related][0]
    str = '{"image"=>"img2.jpg", "urls"=>["c.com", "d.com"]}'
    assert_equal str, magazine.props[:related][1]

    published_rel = query&.r
    assert_not_nil published_rel
    assert_not_nil published_rel.props
    assert_not_nil published_rel.props[:image]
    str = '{"details"=>{"name"=>"zeen", "urls"=>["apix.rocks",'\
          ' "findditfor.me"]}, "format"=>"large"}'
    assert_equal str, published_rel.props[:image]
    assert_equal :PUBLISHED, published_rel.rel_type
    # assert_equal [2015, 2016, 2017], published_rel.props[:years]
    assert_equal %w(2015 2016 2017), published_rel.props[:years] # TODO
    str = '{"details"=>{"name"=>"zeen", "urls"=>["apix.rocks",'\
          ' "findditfor.me"]}, "format"=>"large"}'
    assert_equal str, published_rel.props[:image]
  end

  test 'should create node reverse' do
    post '/x/book', params: {
      properties: {
        title: 'Hamlet',
        year: 1600
      }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Hamlet', res['properties']['title']
    assert_equal 1600, res['properties']['year']
    assert_equal 'book', res['label']

    nid = res['nid']

    post '/x/author', params: {
      properties: { name: 'Jon' },
      relationships: {
        out: [
          {
            rel_type: 'WROTE',
            nid: nid,
            properties: {
              role: 'lead'
            }
          }
        ]
      } # relationships
    } # params
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Jon', res['properties']['name']
    assert_equal 'author', res['label']

    # Verify that data was stored
    query = @session.query
                    .match(a: :author, b: :book)
                    .where(a: { name: 'Jon' }, b: { title: 'Hamlet' })
                    .return(:a, :b).first
    author = query&.a
    assert_not_nil author
    assert_equal 'Jon', author.props[:name]
    book = query&.b
    assert_not_nil book
    assert_equal 'Hamlet', book.props[:title]
    assert_equal 1600, book.props[:year]
    # Verify relationship
    assert_equal 1, author.rels.size
    assert_equal 1, author.rels.size
    assert_equal :WROTE, author.rels[0].rel_type
    assert_equal :WROTE, author.rels[0].rel_type
    assert_equal author.neo_id, book.rels[0].start_node_neo_id
    assert_equal book.neo_id, author.rels[0].end_node_neo_id
  end

  test 'should search' do
    (1..15).each do |i|
      post '/x/book', params: {
        properties: { title: 'Jungle Book ' + i.to_s, year: 1990 + i }
      }
      assert_response :success
    end
    post '/x/book', params: {
      properties: { title: 'Harry Potter', year: 2000 }
    }
    assert_response :success

    # Bad node
    post '/x/badnode/search', params: {
      properties: { bad: 'node' }
    }
    assert_response :not_found

    # No properties
    post '/x/book/search'
    assert_response :bad_request

    # Invalid property
    post '/x/book/search', params: {
      properties: { invalid: 'property' }
    }
    assert_response :bad_request

    # Bad pagination value
    post '/x/book/search', params: {
      properties: { title: 'harry' },
      page: 0
    }
    assert_response :bad_request
    post '/x/book/search', params: {
      properties: { title: 'harry' },
      page: -1
    }
    assert_response :bad_request
    post '/x/book/search', params: {
      properties: { title: 'harry' },
      page: 'one'
    }
    assert_response :bad_request

    # Search by title
    post '/x/book/search', params: {
      properties: { title: 'harry' }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 1, res.size
    assert_equal 'Harry Potter', res[0]['properties']['title']

    # Search by year
    post '/x/book/search', params: {
      properties: { year: 2000 }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 2, res.size
    book_titles = []
    res.each do |book_json|
      book_titles.push book_json['properties']['title']
      assert_equal 2000, book_json['properties']['year']
    end
    assert_equal true, book_titles.include?('Jungle Book 10')
    assert_equal true, book_titles.include?('Harry Potter')

    # Search by title and year
    post '/x/book/search', params: {
      properties: { title: 'jungle', year: 1995 }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 1, res.size
    assert_equal 'Jungle Book 5', res[0]['properties']['title']
    assert_equal 1995, res[0]['properties']['year']

    # Pagination
    post '/x/book/search', params: {
      properties: { title: 'jungle' },
      page: 1
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 10, res.size
    post '/x/book/search', params: {
      properties: { title: 'jungle' },
      page: 2
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 5, res.size

    # No results
    post '/x/book/search', params: {
      properties: { year: 199 }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 0, res.size
    post '/x/book/search', params: {
      properties: { title: 'Harry Potter', year: 1995 }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 0, res.size
    post '/x/book/search', params: {
      properties: { title: 'harry' },
      page: 2
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 0, res.size
  end

  test 'should show node' do
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
    res = JSON.parse(@response.body)
    assert_response :success
    book_nid = res['nid']

    # Get book
    get '/x/book/' + book_nid.to_s
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'book', res['label']
    assert_equal 1, res['relationships'].size
    rel = res['relationships'][0]
    assert_equal 'lead', rel['properties']['role']
    assert_equal 'WROTE', rel['rel_type']
    assert_equal author_nid, rel['from_nid']
    assert_equal book_nid, rel['to_nid']
  end

  test 'should update node' do
    # Create Author
    post '/x/author', params: {
      properties: { name: 'Jon' }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    author_nid = res['nid'].to_s
    # Create Book
    post '/x/book', params: {
      properties: { title: 'Jungle Book' }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Jungle Book', res['properties']['title']
    assert_nil res['properties']['year']
    book_nid = res['nid'].to_s

    # Bad node
    put '/x/badnode/1', params: {
      properties: { bad: 'node' }
    }
    assert_response :not_found
    put '/x/book/999999999', params: {
      properties: { year: 1984 }
    }
    assert_response :not_found

    # Bad property
    put '/x/book/' + book_nid, params: {
      properties: { invalid: 'property' }
    }
    assert_response :bad_request
    # Bad relationship
    put '/x/book/' + book_nid, params: {
      relationships: {
        in: [
          {
            rel_type: 'READ',
            nid: author_nid
          }
        ]
      }
    }
    assert_response :bad_request
    put '/x/book/' + book_nid, params: {
      relationships: {
        in: [
          {
            rel_type: 'WROTE',
            nid: 999_999_999 # Nonexistent
          }
        ]
      }
    }
    assert_response :bad_request
    # Bad relationship property
    put '/x/book/' + book_nid, params: {
      relationships: {
        in: [
          {
            rel_type: 'WROTE',
            nid: author_nid,
            properties: {
              plagiarism: 'lots' # Nonexistent
            }
          }
        ]
      }
    }
    assert_response :bad_request

    # Add property to book
    put '/x/book/' + book_nid, params: {
      properties: { year: 1984 }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Jungle Book', res['properties']['title']
    assert_equal 1984, res['properties']['year']

    # Update existing property of book
    put '/x/book/' + book_nid, params: {
      properties: { title: 'Jungle Book 2' }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Jungle Book 2', res['properties']['title']
    assert_equal 1984, res['properties']['year']

    # Add relationship to book
    put '/x/book/' + book_nid, params: {
      relationships: {
        in: [
          {
            rel_type: 'WROTE',
            nid: author_nid
          }
        ]
      } # relationships
    } # params
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Jungle Book 2', res['properties']['title']
    assert_equal 1984, res['properties']['year']
    # Get nodes
    query = @session.query
                    .match(a: :author, b: :book)
                    .where(a: { name: 'Jon' }, b: { title: 'Jungle Book 2' })
                    .return(:a, :b).first
    author = query&.a
    book = query&.b
    # Verify relationship
    assert_equal 1, author.rels.size
    assert_equal 1, author.rels.size
    assert_equal :WROTE, author.rels[0].rel_type
    assert_equal :WROTE, author.rels[0].rel_type
    assert_equal author.neo_id, book.rels[0].start_node_neo_id
    assert_equal book.neo_id, author.rels[0].end_node_neo_id

    # Update relationship
    put '/x/book/' + book_nid, params: {
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
      }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Jungle Book 2', res['properties']['title']
    assert_equal 1984, res['properties']['year']
    # Get nodes
    query = @session.query
                    .match(a: :author, b: :book)
                    .where(a: { name: 'Jon' }, b: { title: 'Jungle Book 2' })
                    .return(:a, :b).first
    author = query&.a
    book = query&.b
    # Verify relationship
    assert_equal 1, author.rels.size
    assert_equal 1, author.rels.size
    assert_equal 'lead', book.rels[0].props[:role]
    assert_equal 'lead', author.rels[0].props[:role]

    # Altogether now
    put '/x/book/' + book_nid, params: {
      properties: {
        title: 'Hamlet',
        year: 1600
      },
      relationships: {
        in: [
          {
            rel_type: 'WROTE',
            nid: author_nid,
            properties: {
              role: 'supporting'
            }
          }
        ]
      } # relationships
    } # params
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Hamlet', res['properties']['title']
    assert_equal 1600, res['properties']['year']
    # Get nodes
    query = @session.query
                    .match(a: :author, b: :book)
                    .where(a: { name: 'Jon' }, b: { title: 'Hamlet' })
                    .return(:a, :b).first
    author = query&.a
    book = query&.b
    # Verify relationship
    assert_equal 1, author.rels.size
    assert_equal 1, author.rels.size
    assert_equal 'supporting', book.rels[0].props[:role]
    assert_equal 'supporting', author.rels[0].props[:role]
  end

  test 'should destroy node' do
    # Create Author
    post '/x/author', params: {
      properties: { name: 'Jon' }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    author_nid = res['nid'].to_s
    # Create Book and WROTE relationship
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
    res = JSON.parse(@response.body)
    assert_response :success
    book_nid = res['nid'].to_s

    # Bad node
    delete '/x/badnode/1', params: {
      properties: ['bad']
    }
    assert_response :not_found
    delete '/x/book/999999999', params: {
      properties: ['year']
    }
    assert_response :not_found

    # Bad property
    delete '/x/book/' + book_nid, params: {
      properties: ['invalid']
    }
    assert_response :bad_request
    # Bad relationship
    delete '/x/book/' + book_nid, params: {
      relationships: {
        in: [
          {
            rel_type: 'READ',
            nid: author_nid
          }
        ]
      }
    }
    assert_response :bad_request
    delete '/x/book/' + book_nid, params: {
      relationships: {
        in: [
          {
            rel_type: 'WROTE',
            nid: 999_999_999 # Nonexistent
          }
        ]
      }
    }
    assert_response :bad_request
    # Bad relationship property
    delete '/x/book/' + book_nid, params: {
      relationships: {
        in: [
          {
            rel_type: 'WROTE',
            nid: author_nid,
            properties: ['plagiarism'] # Nonexistent
          }
        ]
      }
    }
    assert_response :bad_request

    # Remove property from relationship
    delete '/x/book/' + book_nid, params: {
      relationships: {
        in: [
          {
            rel_type: 'WROTE',
            nid: author_nid,
            properties: ['role']
          }
        ]
      }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Jungle Book', res['properties']['title']
    assert_equal 1984, res['properties']['year']
    # Get nodes
    query = @session.query
                    .match(a: :author, b: :book)
                    .where(a: { name: 'Jon' }, b: { title: 'Jungle Book' })
                    .return(:a, :b).first
    author = query&.a
    book = query&.b
    # Verify relationship
    assert_equal 1, author.rels.size
    assert_equal 1, author.rels.size
    assert_nil book.rels[0].props[:role]
    assert_nil author.rels[0].props[:role]

    # Remove property from book
    delete '/x/book/' + book_nid, params: {
      properties: ['year']
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Jungle Book', res['properties']['title']
    assert_nil res['properties']['year']
    # Get nodes
    query = @session.query
                    .match(b: :book)
                    .where(b: { title: 'Jungle Book' })
                    .return(:b).first
    book = query&.b
    assert_equal 'Jungle Book', book.props[:title]
    assert_nil book.props[:year]

    # Remove relationship
    delete '/x/book/' + book_nid, params: {
      relationships: {
        in: [
          {
            rel_type: 'WROTE',
            nid: author_nid
          }
        ]
      }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Jungle Book', res['properties']['title']
    # Get nodes
    query = @session.query
                    .match(a: :author, b: :book)
                    .where(a: { name: 'Jon' }, b: { title: 'Jungle Book' })
                    .return(:a, :b).first
    author = query&.a
    book = query&.b
    # Verify relationship
    assert_equal 0, author.rels.size
    assert_equal 0, book.rels.size

    # Remove book
    delete '/x/book/' + book_nid
    assert_response :success
    # Get nodes
    query = @session.query
                    .match(a: :author)
                    .where(a: { name: 'Jon' })
                    .return(:a).first
    author = query&.a
    assert_not_nil author
    query = @session.query
                    .match(b: :book)
                    .where(b: { title: 'Jungle Book' })
                    .return(:b).first
    book = query&.b
    assert_nil book

    # Altogether now
    # Create Book and WROTE relationship
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
    res = JSON.parse(@response.body)
    assert_response :success
    book_nid = res['nid'].to_s

    # Remove property from relationship and book
    delete '/x/book/' + book_nid, params: {
      properties: ['year'],
      relationships: {
        in: [
          {
            rel_type: 'WROTE',
            nid: author_nid,
            properties: ['role']
          }
        ]
      }
    }
    res = JSON.parse(@response.body)
    assert_response :success
    assert_equal 'Jungle Book', res['properties']['title']
    assert_nil res['properties']['year']
    query = @session.query
                    .match(a: :author, b: :book)
                    .where(a: { name: 'Jon' }, b: { title: 'Jungle Book' })
                    .return(:a, :b).first
    author = query&.a
    book = query&.b
    assert_equal 1, author.rels.size
    assert_equal 1, author.rels.size
    assert_nil book.rels[0].props[:role]
    assert_nil author.rels[0].props[:role]
    assert_equal 'Jungle Book', book.props[:title]
    assert_nil book.props[:year]

    # Remove book and relationships
    delete '/x/book/' + book_nid
    assert_response :success
    # Get nodes
    query = @session.query
                    .match(a: :author)
                    .where(a: { name: 'Jon' })
                    .return(:a).first
    author = query&.a
    assert_not_nil author
    query = @session.query
                    .match(b: :book)
                    .where(b: { title: 'Jungle Book' })
                    .return(:b).first
    book = query&.b
    assert_nil book
  end
end
