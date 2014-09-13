require 'shellwords'

module Commands
  extend self

  def sh!(*command)
    command = prep_command_array(command)
    output = `#{Shellwords.join(command)} 2>&1`
    raise "Command failed: #{command.join(' ')}. Output:\n#{output}" unless $?.success?
    output
  end

  def sh_ok?(*command)
    command = prep_command_array(command)
    `#{Shellwords.join(command)} 2>&1`
    $?.success?
  end

  def prep_command_array(command)
    command = [command] unless command.is_a?(Array)
    command.flatten
  end
end
