module Helpers
  module Nested
    def nested(levels, opts = {})
      opts.inject({}) do |acc, elem|
        key, value = elem
        acc.update(key => levels == 0 ? value : nested(levels - 1, opts))
      end
    end
  end
end
