require 'set'

module Jac
  module Configuration
    # Merges two hashes with following value resolve strategy:
    # * When having both `that: Hash` and `other: Hash` for same key will merge
    #   them with same strategy and return result
    # * When having Set and Enumerable will join two sets into
    #   one
    # * When having Set and nil will return Set
    # * Return `other` value in all other cases
    class Merger
      # Returns a new hash with base and overrides merged recursively.
      # @param [Hash] base values
      # @param [Hash] other values
      # @return [Hash] updated hash
      def merge(base, other)
        merge!(base.dup, other)
      end

      # Returns a new hash with base and overrides merged recursively. Updates
      # receiver
      # @param [Hash] base values
      # @param [Hash] other values
      # @return [Hash] updated base hash
      def merge!(base, other)
        # base.merge!(other, &method(:resolve_values))
        base.merge!(other) do |key, base_value, other_value|
          resolve_values(key, base_value, other_value)
        end
      end

      # @param [Object] _key
      # @param [Object] base
      # @param [Object] other
      # @return [Object] resolved value
      def resolve_values(_key, base, other)
        if base.nil? && other.nil?
          nil
        elsif to_hash?(base, other)
          merge(base, other)
        elsif to_set?(base, other)
          Set.new(base) + Set.new(other)
        else
          other
        end
      end

      private

      def to_hash?(base, other)
        base.is_a?(Hash) && other.is_a?(Hash)
      end

      def to_set?(base, other)
        (base.is_a?(Set) && set_like?(other)) || (other.is_a?(Set) && set_like?(base))
      end

      # rubocop: disable Naming/AccessorMethodName
      def set_like?(value)
        value.is_a?(Enumerable) || value.nil?
      end
      # rubocop: enable Naming/AccessorMethodName
    end
  end
end
