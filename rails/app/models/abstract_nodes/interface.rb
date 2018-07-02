class Interface < AbstractNode
  def as_json(options = {})
    json = super({}.merge(options))
    # Manually call as_json (implicitly) for fields that are models
    json['properties'] = properties
    json
  end
end
