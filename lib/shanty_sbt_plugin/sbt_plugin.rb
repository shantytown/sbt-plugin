require 'subprocess'
require 'json'
require 'shanty_sbt_plugin/sbt_process'
require 'shanty/artifact'
require 'shanty/logger'
require 'shanty/plugin'
require 'tempfile'

module SbtPlugin
  class SbtPlugin < Shanty::Plugin
    include Shanty::Logger

    SCALA = 'import sbt._
  import sbt.Keys._

  def getSetting[T](pr: ProjectRef, key: SettingKey[T]): Option[T] =
    key.in(pr).get(structure.data)
  val projectInfo = structure.allProjectRefs.map { pr =>
    val ap: Option[String] = (for {
      t <- getSetting(pr, crossTarget)
      module <- getSetting(pr, projectID)
      a <- getSetting(pr, artifact)
      sv <- getSetting(pr, scalaVersion)
      sbv <- getSetting(pr, scalaBinaryVersion)
      toString <- getSetting(pr, artifactName)
    } yield ((t / toString(ScalaVersion(sv, sbv), module, a)).asFile).toString)
   (pr.project, (getSetting(pr, name).getOrElse(""),
                 getSetting(pr, libraryDependencies).map(_.map(_.toString)).getOrElse(Seq[String]()),
                 getSetting(pr, scalaVersion).getOrElse(""),
                 getSetting(pr, artifactPath).map(_.toString).getOrElse(ap.getOrElse(""))))
  }.toMap

  def toJsonArray(v: Seq[String]): String =
    "[ " + v.map(x => s""""${x}"""").mkString(",") + " ]"

  structure.allProjects.map{ project =>
    s"""JSON { "${project.id}": { "plugins": "${project.plugins}", "configurations": ${toJsonArray(project.configurations.map(_.toString))}, "autoPlugins": ${toJsonArray(project.autoPlugins.map(_.toString))}, "name": "${projectInfo(project.id)._1}", "path": "${project.base.toString}", "artifact": "${projectInfo(project.id)._4}", "dependencies": ${toJsonArray(project.dependencies.map(_.project.project))}, "libraries": ${toJsonArray(projectInfo(project.id)._2)} } }"""
  }.foreach(println)

  println("ENDJSON")
  '

    def self.dependencies(env)
      projects = sbt_projects(env)
      projects.values.each do |project|
        project.config[:sbt_dependencies].each do |dep_id|
          project.add_parent(projects[dep_id])
        end
      end
    end

    def do_build
      logger.info(process.send_command("project #{project.config[:sbt_id]}"))
      logger.info(process.send_command('package'))
    end

    def artifacts
      [Shanty::Artifact.new(File.extname(artifact).delete('.'), 'sbt', URI("file://#{artifact}"))]
    end

    private_class_method

    def self.sbt_projects(env)
      env.file_tree.glob('**/project').each_with_object({}) do |project_dir, acc|
        project_dir = File.expand_path(File.join(project_dir, '..'))
        next unless File.exist?(File.join(project_dir, 'build.sbt'))

        projects = find_projects(project_dir, env)
        # if this is a multi-project do not include the root project
        projects.delete_if { |_, p| p.path == project_dir } if projects.size != 1

        acc.merge!(projects)
      end
    end

    def self.find_projects(project_dir, env)
      process = SbtProcess.new(project_dir)
      project_info(process).each_with_object({}) do |(id, info), a|
        project = find_or_create_project(info['path'], env)
        setup_project(project, process, project_dir, id, info)

        a["#{project_dir}:#{id}"] = project
      end
    end

    def self.setup_project(project, process, project_dir, id, info)
      project.config[:sbt_id] = id
      project.config[:sbt_project_name] = info['name']
      project.config[:sbt_root] = project_dir
      project.config[:sbt_dependencies] = sbt_dependencies(info, project_dir)
      project.config[:sbt_process] = process
      project.config[:sbt_artifact] = info['artifact']
    end

    def self.sbt_dependencies(info, project_dir)
      info['dependencies'].map { |d| "#{project_dir}:#{d}" }
    end

    def self.project_info(process)
      process.send_command('console-project', /\Ascala>\z/)
      info_text = process.send_command(SCALA, /\AENDJSON\z/)
      process.send_command('exit')

      info_text.each_line.each_with_object({}) do |line, acc|
        next unless line.start_with?('JSON')
        acc.merge!(JSON.parse(line.delete('JSON')))
      end
    end

    private

    def process
      project.config[:sbt_process]
    end

    def artifact
      project.config[:sbt_artifact]
    end

    Signal.trap('TERM') { clean_up }
    Signal.trap('EXIT') { clean_up }

    def clean_up
      env.projects.map { |p| p.config[:sbt_process] }.compact.each do |proc|
        proc.stdin.close
        proc.wait
      end
    end
  end
end
