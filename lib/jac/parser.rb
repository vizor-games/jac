require 'psych'
require 'set'

require_relative 'value'

module Jac
  # Custom YAML parsing routines
  module Parser
    # List of features supported in Psych by version
    FEATURES = {
      locations: '>=3.0.2' # Psych::Node contains start_line, end_line,
      # start_column, end_column
    }.freeze

    class << self
      def features(psych_version = Psych::VERSION)
        FEATURES
          .select { |_k, v| Versions.match(psych_version, v) }
          .keys
      end
    end
    # Cutstom Yaml AST visitor
    # @see Psych::Visitors::ToRuby
    # While standard Psych visitor converts sets to `{ value => nil }` mappings
    # we need explicitly convert those mappings to ruby [Set]
    class VisitorToRuby < Psych::Visitors::ToRuby
      attr_accessor :stream_name

      # Uses standard Psych visitor to convert mapping to ruby object
      # except `!set` case. Here we convert mapping to [Set].
      # @param [Psych::Nodes::Mapping] o YAML AST node
      # @return [Object] parsed ruby object
      def visit_Psych_Nodes_Mapping(o) # rubocop:disable Naming/MethodName
        case o.tag
        when '!set', 'tag:yaml.org,2002:set'
          visit_set(o)
        else # fallback to default implementation
          super(o)
        end
      end

      def accept(o)
        attributes = { source: stream_name }
        if Parser.features.include?(:locations)
          attributes[:start_line] = o.start_line
          attributes[:end_line] = o.end_line
          attributes[:start_column] = o.start_column
          attributes[:end_column] = o.end_column
        end
        Values.of(super(o), attributes)
      end

      private

      def visit_set(o)
        set = Set.new
        # Update anchor
        @st[o.anchor] = set if o.anchor
        o.children.each_slice(2) do |k, _v|
          set << accept(k)
        end
        set
      end
    end
  end
end
