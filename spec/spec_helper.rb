require 'simplecov'
require 'coveralls'
require 'fileutils'
require 'logger'
require 'pathname'
require 'tmpdir'

require_relative 'support/contexts/plugin'
require_relative 'support/contexts/sbt_projects'
require_relative 'support/contexts/workspace'
require_relative 'support/matchers/call_me_ruby'
require_relative 'support/matchers/plugin'

SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter '/spec/'
end

RSpec.configure do |config|
  config.expect_with(:rspec) do |c|
    c.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with(:rspec) do |mocks|
    mocks.verify_partial_doubles = true
  end
end
