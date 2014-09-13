#!/usr/bin/env ruby

require 'tmpdir'
require 'shellwords'
require 'fileutils'
require 'date'
require 'test/unit'

class TestThinBackups < Test::Unit::TestCase
  
  def setup
    @script = File.expand_path(File.dirname(__FILE__) + "/../thin-backups.rb")
  end
  
  def test_basic_functionality
    in_tmpdir do
      times = some_times
      make_files(times)
      
      rules = ["3:1,3,5,7", "8:"]
      today = Date.new(2010, 3, 10).to_s
      run_script(rules, today)
      
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
      check_result(times, expected_times)
    end
  end
  
  def test_pretend
    in_tmpdir do
      times = some_times
      make_files(times)
      
      rules = ["3:1,3,5,7", "8:"]
      today = Date.new(2010, 3, 10).to_s
      run_script(rules, today, ['-q', '--pretend'])
      
      check_result(times, times)
    end
  end
  
private
  def in_tmpdir(&block)
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        block.call
      end
    end
  end
  
  def make_files(times)
    times.map {|t| t.gsub(' ', '') }.each {|t| FileUtils.touch("foo-#{t}.tar.gz") }
  end
  
  def some_times
    [
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
  end
  
  def check_result(times, expected_times)
    times.each do |t|
      filename = "foo-#{t.gsub(' ', '')}.tar.gz"
      if expected_times.include?(t)
        assert(File.exist?(filename), "Deleted but should have remained: #{filename}")
      else
        assert(!File.exist?(filename), "Remained but should have been deleted: #{filename}")
      end
    end
  end
  
  def run_script(rules, initial_date, extra_args = ['-q'])
    args = ['-s', initial_date] + extra_args + ['.'] + rules
    system(Shellwords.join([@script, *args]))
    raise $?.inspect unless $?.success?
  end
end
