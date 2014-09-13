require 'commands'
require 'files'
require 'fileutils'

class SetUpBackupreaderPlugin
  def self.title
    "Set up 'backupreader' user and group."
  end

  def run
    create_user_unless_exists
    set_up_authorized_keys
    set_up_sshd_unless_done
  end

  private

  def create_user_unless_exists
    unless Commands.sh_ok?('getent', 'passwd', 'backupreader')
      puts "Creating user 'backupreader'"
      Commands.sh!('adduser', '--system', '--group', 'backupreader')
    else
      puts "User 'backupreader' already exists. Skipping creating it."
    end
  end

  def set_up_authorized_keys
    if Prompts.yesno("Would you like to paste a public SSH key for backupreader now?")
      key = Prompts.prompt("Please paste it here") do |input|
        !input.strip.empty?
      end
      key.strip!

      if File.exists?(authorized_keys_file)
        old_lines = File.readlines(authorized_keys_file).map(&:strip)
      else
        old_lines = []
      end

      unless old_lines.include?(key)
        FileUtils.mkdir_p(File.dirname(authorized_keys_file))
        File.open(authorized_keys_file, "a") do |f|
          f.puts unless old_lines.empty? || old_lines.last.empty?
          f.puts key
        end
        puts "Key written to #{authorized_keys_file}"
        Commands.sh!('chown', '-R', 'backupreader', File.dirname(authorized_keys_file))
        Commands.sh!('chmod', 'og-rwx', authorized_keys_file)
      else
        puts "Key already exists. Will not duplicate."
      end
    end
    puts
  end

  def set_up_sshd_unless_done
    unless sshd_file_already_set_up?
      puts "Adding #{match_user_line} clause to #{sshd_file}"
      File.open(sshd_file, "a") do |f|
        f.puts
        f.puts match_user_line
        f.puts "    ChrootDirectory /backup/ready"
        f.puts "    AllowTcpForwarding no"
        f.puts "    X11Forwarding no"
        f.puts "    ForceCommand internal-sftp"
        f.puts
      end
      puts
      if Prompts.yesno("Shall I reload the SSH daemon?")
        Commands.sh!('service', 'ssh', 'reload')
        puts "Done."
      end
      puts
    else
      puts "#{sshd_file} already set up. Skipping."
    end
  end

  def sshd_file_already_set_up?
    File.readlines(sshd_file).map(&:strip).any? {|line| line == match_user_line }
  end

  def sshd_file
    '/etc/ssh/sshd_config'
  end

  def authorized_keys_file
    '/home/backupreader/.ssh/authorized_keys'
  end

  def match_user_line
    "Match User backupreader"
  end
end
