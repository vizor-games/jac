require 'psych'
require 'set'

module Jac
  # Custom YAML parsing routines
  module Parser
    # Cutstom Yaml AST visitor
    # @see Psych::Visitors::ToRuby
    # While standard Psych visitor converts sets to `{ value => nil }` mappings
    # we need explicitly convert those mappings to ruby [Set]
    class VisitorToRuby < Psych::Visitors::ToRuby
      # rubocop: disable Naming/MethodName

      # Uses standard Psych visitor to convert mapping to ruby object
      # except `!set` case. Here we convert mapping to [Set].
      # @param [Psych::Nodes::Mapping] o YAML AST node
      # @return [Object] parsed ruby object
      def visit_Psych_Nodes_Mapping(o)
        case o.tag
        when '!set', 'tag:yaml.org,2002:set'
          visit_set(o)
        else # fallback to default implementation
          super(o)
        end
      end
      # rubocop: enable Naming/MethodName

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
