# Utilitary module for comparing versions
module Versions
  class << self
    OPERATORS = {
      '>=' => :>=,
      '<=' => :<=,
      '=' => :==
    }.freeze
    # Tries to match provided version with target rule
    # If version matches, will return version value. If not, returns nil.
    # Target rule can be described in following walys
    # * '=x.y.z' - exact match with version
    # * '>=x.y.z' - requires minimum version as x.y.z
    # * '<=x.y.z' - limits wersion with x.y.z
    #
    # @param version [String] verstion string to match
    # @param target_rule [String] rule describing version requirement
    # @return [String] version string or nil, if version don't match
    #  rule
    def match(version, target_rule)
      op, v = target_rule.match(/^(=|>=|<=)(.+)$/) do |m|
        [OPERATORS[m[1]], m[2]]
      end

      raise('Version format does not match: ' + target_rule) unless op
      return version if version.send(op, v)
    end
  end
end
