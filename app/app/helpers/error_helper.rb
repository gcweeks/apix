module ErrorHelper
  class Error < StandardError; end
  class BadRequest < Error
    def initialize(data = nil)
      @data = data
    end
    attr_reader :data
  end
  class Unauthorized < Error
    def initialize(data = nil)
      @data = data
    end
    attr_reader :data
  end
  class PaymentRequired < Error
    def initialize(data = nil)
      @data = data
    end
    attr_reader :data
  end
  class NotFound < Error
    def initialize(data = nil)
      @data = data
    end
    attr_reader :data
  end
  class UnprocessableEntity < Error
    def initialize(data = nil)
      @data = data
    end
    attr_reader :data
  end
  class InternalServerError < Error
    def initialize(data = nil)
      @data = data
    end
    attr_reader :data
  end
end
