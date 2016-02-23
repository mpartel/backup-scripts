require 'prompts'
require 'files'

class PostgresPlugin
  def self.title
    "Set up PostgreSQL dump."
  end

  def run
    while true
      @name = ask_name
      @dbs = ask_databases

      break if Prompts.yesno("Ready to write backup script to #{script_file} ?")
    end
    write_scripts!
  end

  def ask_name
    Prompts.prompt("Please give an identifier for this backup") do |ident|
      !!(ident =~ /^[a-zA-Z_][a-zA-Z0-9_-]*$/)
    end
  end

  def ask_databases
    Prompts.prompt("Please give a space-separated list of databases to back up") do |dbs|
      !dbs.blank?
    end.strip.split(/\s+/)
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
    @dbs.each do |db|
      esc_db = Shellwords.escape(db)
      script << "echo \"Dumping database:\" #{esc_db}"
      script << "sudo -u postgres pg_dump #{esc_db} | gzip " +
        "| tee \"$STAGING/#{esc_db}.sql.gz\" " +
        "| sha1sum | sed 's/  -/  #{esc_db}.sql.gz/' >> \"$STAGING/SHA1SUMS\""
    end
    script << ""
    script << "move_staging_to_ready"
    script << ""

    Files.write_file(script_file, script.join("\n"))
    FileUtils.chmod('a+x', script_file)
  end
end
