require 'fileutils'

module Files
  extend self

  def write_file(file, contents)
    FileUtils.mkdir_p(File.dirname(file))
    File.open(file, "wb") {|f| f.write(contents) }
  end

  def project_dir
    @project_dir ||= File.dirname(File.dirname(File.realpath(__FILE__)))
  end

  def script_dir
    '/backup/scripts'
  end

  def install_common_files!
    common_files.each {|f| install_common_file(f) }
  end

  def common_files
    ['common.sh', 'backup-all.sh']
  end

  def install_common_file(file_name)
    puts "Installing #{file_name} to #{script_dir}"
    FileUtils.mkdir_p(script_dir)
    src = project_dir + '/' + file_name
    dest = script_dir + '/' + file_name
    FileUtils.cp(src, dest, :preserve => true)
  end
end
