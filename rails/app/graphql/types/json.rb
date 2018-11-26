class Types::JSON < Types::BaseScalar
  def self.coerce_input(input_value, _context)
    # Parse the incoming JSON into a hash
    JSON.parse(input_value)
  rescue
    raise GraphQL::CoercionError, "#{input_value.inspect} is not valid JSON"
  end

  def self.coerce_result(ruby_value, _context)
    # It's transported as a string, so stringify it
    ruby_value.to_s
  end
end
