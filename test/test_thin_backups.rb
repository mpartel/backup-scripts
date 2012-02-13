#!/usr/bin/env ruby

require 'tmpdir'
require 'shellwords'
require 'fileutils'
require 'date'

script = File.expand_path(File.dirname(__FILE__) + "/../thin-backups.rb")

Dir.mktmpdir do |tmpdir|
  Dir.chdir(tmpdir) do
    times = [
      '2010 03 01', # mon
      '2010 03 02', # tue
      '2010 03 03', # wed
      '2010 03 04', # thu
      '2010 03 05', # fri
      '2010 03 06', # sat
      '2010 03 07', # sun
      '2010 03 08', # mon
      '2010 03 09', # tue
      '2010 03 10'  # wed
    ]
    
    times.map {|t| t.gsub(' ', '') }.each {|t| FileUtils.touch("foo-#{t}.tar.gz") }
    
    rules = "[[3, [1,3,5,7]], [8, []]]"
    
    now = Date.new(2010, 3, 10).to_s
    
    system(Shellwords.join([script, '.', rules, now]))
    raise $?.inspect unless $?.success?
    
    expected_times = [
      #'2010 03 01', # mon
      #'2010 03 02', # tue
      '2010 03 03', # wed
      #'2010 03 04', # thu
      '2010 03 05', # fri
      #'2010 03 06', # sat
      '2010 03 07', # sun
      '2010 03 08', # mon
      '2010 03 09', # tue
      '2010 03 10'  # wed
    ]
    
    times.each do |t|
      filename = "foo-#{t.gsub(' ', '')}.tar.gz"
      if expected_times.include?(t)
        raise "Deleted but should have remained: #{filename}" unless File.exist?(filename)
      else
        raise "Remained but should have been deleted: #{filename}" if File.exist?(filename)
      end
    end
    
    puts "OK"
  end
end
