class ApixSchema < GraphQL::Schema
  ## Default Limits
  # max_depth 10
  # max_complexity 300
  # default_max_page_size 20

  ## Required:
  query Types::QueryType

  ## Optional:
  mutation Types::MutationType
  # subscription Types::Subscription
  # introspection CustomIntrospection
  # orphan_types [Types::Comment, ...]

  ## Object Identification Hooks

  # def self.resolve_type(abstract_type, object, context)
  #   # Disambiguate `object`, from among `abstract_type`'s members
  #   # (`abstract_type` is an interface or union type.)
  # end

  # def self.object_from_id(unique_id, context)
  #   # Find and return the object for `unique_id`
  #   # or `nil`
  # end

  # def self.id_from_object(object, type, context)
  #   # Return a unique ID for `object`, whose GraphQL type is `type`
  # end

  ## Execution Configuration

  # instrument :field, ResolveTimerInstrumentation
  # tracer MetricTracer
  # query_analyzer MyQueryAnalyzer.new
  # lazy_resolve Promise, :sync
  # rescue_from(ActiveRecord::RecordNotFound) { "Not found" }

  # def self.type_error(type_err, context)
  #   # Handle `type_err` in some way
  # end

  ## Context Class

  # context_class CustomContext

  ## Plugins
  # use GraphQL::Tracing::NewRelicTracing
end
