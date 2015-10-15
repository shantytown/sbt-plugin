require 'fileutils'
require_relative 'plugin'

RSpec.shared_context('sbt_projects') do
  include_context('plugin')

  before do
    FileUtils.mkdir_p(project_paths.first)
    FileUtils.mkdir_p(project_paths[1])

    FileUtils.cp_r(File.join(__dir__, '..', 'fixtures', 'single'), project_paths.first)
    FileUtils.cp_r(File.join(__dir__, '..', 'fixtures', 'multi'), project_paths[1])
  end
end
