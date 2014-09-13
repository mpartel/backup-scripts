require 'commands'
require 'files'

class SetUpBackupreaderPlugin
  def self.title
    "Set up 'backupreader' user and group."
  end

  def run
    create_user_unless_exists
    set_up_sshd_unless_done
  end

  private

  def create_user_unless_exists
    unless Commands.sh_ok?('getent', 'passwd', 'backupreader')
      puts "Creating user 'backupreader'"
      Commands.sh!('adduser', '--system', '--group', '--no-create-home', 'backupreader')
    else
      puts "User 'backupreader' already exists. Skipping creating it."
    end
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
      puts "Done. You may want to do: service ssh reload"
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

  def match_user_line
    "Match User backupreader"
  end
end
