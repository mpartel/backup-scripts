require 'commands'
require 'files'
require 'prompts'

class SetUpCrontabPlugin
  def self.title
    "Write #{cron_d_file} to run #{scheduled_command}."
  end

  def run
    unless Dir.exists?(File.dirname(self.class.cron_d_file))
      raise "#{File.dirname(self.class.cron_d_file)} does not exist.\n" +
              "This is a Debian-specific feature.\n" +
              "Please write your crontab manually."
    end

    if File.exists?(self.class.cron_d_file)
      puts "Note: #{self.class.cron_d_file} already exists. Here are its contents:"
      puts File.read(self.class.cron_d_file)
      puts
    end

    prompt_text = "Please enter a cron timing\n" +
      "Format: min hour day-of-month month day-of-week\n"
    timing = Prompts.prompt(prompt_text, default = '45 4 * * *') do |line|
      line.start_with?('@') || line.split(/\s+/).size == 5
    end

    cron_line = "#{timing} root #{self.class.scheduled_command}"
    File.write(self.class.cron_d_file, cron_line)

    puts "Wrote #{self.class.cron_d_file} as:\n#{cron_line}"
  end

  private

  def self.cron_d_file
    '/etc/cron.d/backup-all'
  end

  def self.scheduled_command
    '/backup/scripts/backup-all.sh'
  end
end
