#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')

require 'shellwords'
require 'readline'
require 'active_support/core_ext/string'
require 'prompts'
require 'plugins'

class InteractiveSetup
  def run
    check_root

    catch :cancel do
      plugin = choose_plugin
      plugin.new.run
    end
  end

  def check_root
    raise "This script must be run as root." if Process.euid != 0
  end

  def choose_plugin
    Prompts.multiselect('What shall we do?', Plugins.plugins, &:title)
  end
end


InteractiveSetup.new.run
