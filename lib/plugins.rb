
module Plugins
  # A plugin must implement the following methods:
  # - self.title
  # - run

  def self.plugin_directory
    @plugin_directory ||= File.dirname(File.dirname(File.realpath(__FILE__))) + '/plugins'
  end

  def self.plugins
    @plugins = begin
      plugin_files = Dir.entries(plugin_directory).
        select {|e| e.end_with?('_plugin.rb') }.
        sort.
        map {|e| plugin_directory + '/' + e }
     plugin_files.map do |file|
       require file
       class_name = File.basename(file, '.rb').camelize
       const_get(class_name)
     end
    end
  end
end
