class Types::JSON < Types::BaseScalar
  def self.coerce_input(input_value, _context)
    # No coersion needed on input, comes in as Hash automatically
    input_value
  rescue
    raise GraphQL::CoercionError, "#{input_value.inspect} is not valid JSON"
  end

  def self.coerce_result(ruby_value, _context)
    # Output as JSON string rather than Ruby Hash string
    JSON.dump(ruby_value)
  end
end
