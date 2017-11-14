require 'tmpdir'
require 'powerpack/string'
require_relative './helpers/nested'

# @param [String] path relative to lib folder
# @return [String] full path
def lib(path)
  File.join(__dir__, '..', 'lib', path)
end

RSpec.configure do |c|
  c.include Helpers::Nested, nested: true
end
