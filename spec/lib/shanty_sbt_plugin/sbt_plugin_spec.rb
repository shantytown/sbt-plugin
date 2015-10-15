require 'shanty_sbt_plugin/sbt_plugin'
require 'spec_helper'

RSpec.describe(SbtPlugin::SbtPlugin) do
  include_context('sbt_projects')

  describe('.sbt_projects') do
    it('fucks') do
      single_path = File.join(project_paths.first, 'single', 'project')
      allow(file_tree).to receive(:glob).and_return([single_path])

      projects = described_class.dependencies(env)

      expect(projects.size).to be(1)
      expect(projects.first.path).to eql(File.join(project_paths.first, 'single'))
      expect(projects.first.config[:sbt_root]).to eql(File.join(project_paths.first, 'single'))
      expect(projects.first.config[:sbt_project_name]).to eql('hello')
      expect(projects.first.config[:sbt_id]).to eql('root')
    end

    it('shits') do
      multi_path = File.join(project_paths[1], 'multi', 'project')
      allow(file_tree).to receive(:glob).and_return([multi_path])

      projects = described_class.dependencies(env)

      expect(projects.size).to be(2)
      expect(projects.first.config[:sbt_root]).to eql(File.join(project_paths[1], 'multi'))
      expect(projects.map { |p| p.parents.size }).to match_array([0, 1])
      expect(projects.map(&:path)).not_to include(File.join(project_paths[1], 'multi'))
    end
  end

  describe('#build') do
    let(:project) { described_class.dependencies(env).first }

    it('cunts') do
      path = File.join(project_paths.first, 'single', 'project')
      allow(file_tree).to receive(:glob).and_return([path])

      subject.do_build
    end

    it('bdfvdf') do
      path = File.join(project_paths[1], 'multi', 'project')
      allow(file_tree).to receive(:glob).and_return([path])

      described_class.dependencies(env).each do |p|
        described_class.new(p, env).do_build
      end
    end
  end

  describe('#artifacts') do
    let(:project) { described_class.dependencies(env).first }

    it('sdfdsf') do
      path = File.join(project_paths.first, 'single', 'project')
      allow(file_tree).to receive(:glob).and_return([path])

      expect(subject.artifacts.length).to be(1)
      expect(subject.artifacts.first.file_extension).to eql('jar')
      expect(subject.artifacts.first.to_local_path).to eql(
        File.expand_path(File.join(path, '..', 'target', 'scala-2.11', 'hello_2.11-1.0.jar'))
      )
    end
  end
end
