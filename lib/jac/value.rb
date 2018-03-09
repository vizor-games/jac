require 'set'

module Jac
  module Values
    class << self
      def of(o, attributes = {})
        klass = case o
                when Array
                  ArrayValue
                when Hash
                  HashValue
                when Set
                  SetValue
                when String
                  StringValue
                else
                  ObjectValue
                end

        klass.new(o, attributes)
      end
    end

    # Value class keeps track of where value
    # comes from, its context, etc.
    class Value
      def initialize(o, attributes)
        @object = o
        @attributes = OpenStruct.new(attributes)
      end

      def _value
        @object
      end

      def method_missing(meth, *args, &block)
        @object.send(meth, *args, &block)
      end
    end

    class ArrayValue < Value
      def _value
        @object.map(&:_value)
      end
    end

    class HashValue < Value
      def _value
        @object.inject({}) do |acc, elem|
          k, v = elem.map(&:_value)
          acc.update(k => v)
        end
      end
    end

    class StringValue < Value
    end

    class SetValue < Value
      def _value
        Set.new(@object.map(&:_value))
      end
    end

    class ObjectValue < Value
    end
  end
end
