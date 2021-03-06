require 'prompts'
require 'files'
require 'strings'
require 'fileutils'
require 'shellwords'

class TarPlugin
  def self.title
    "Set up backup that makes a tar archive."
  end

  def run
    while true
      @name = ask_name
      @srcdir = ask_srcdir

      break if Prompts.yesno("Ready to write backup script to #{script_file} ?")
    end
    write_scripts!
  end

  def ask_name
    Prompts.prompt("Please give an identifier for this backup") do |ident|
      !!(ident =~ /^[a-zA-Z_][a-zA-Z0-9_-]*$/)
    end
  end

  def ask_srcdir
    Prompts.file_prompt("Source directory?").chomp('/')
  end

  def script_file
    "/backup/scripts/backup-#{@name}.sh"
  end

  def write_scripts!
    Files.install_common_files!

    puts "Creating #{script_file}"
    script = []
    script << "#!/bin/bash -e"
    script << "BACKUP_NAME=#{Shellwords.escape(@name)}"
    script << '. `dirname "$0"`/common.sh'
    script << ""
    script << "rm -f \"$STAGING/SHA1SUMS\""
    script << ""
    script << "echo \"Tarring $STAGING/#{@name}.tar.gz\""
    script <<
      begin
        tarcmd = ['tar']
        tarcmd << '-C' << '/'
        tarcmd << '--one-file-system'
        tarcmd << '-cpz'
        tarcmd << @srcdir.reverse.chomp('/').reverse
        tarcmd << "| tee \"$STAGING/#{@name}.tar.gz\""
        tarcmd << "| sha1sum | sed 's/  -/  #{@name}.tar.gz/' "
        tarcmd << ">> \"$STAGING/SHA1SUMS\""
        tarcmd.join(' ')  # note: not Shellwords.join
      end
    script << ""
    script << "move_staging_to_ready"
    script << ""

    Files.write_file(script_file, script.join("\n"))
    FileUtils.chmod('a+x', script_file)
  end
end
