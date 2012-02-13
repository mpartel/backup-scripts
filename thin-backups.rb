#!/usr/bin/env ruby
# Usage: thin-backups.rb <directory>
# Given a backup directory with files like foo-YYYYMMDD.tar.(gz|bz2),
# removes some backups that are older than the configured time(s).

require 'rubygems'
require 'active_support/core_ext/date/conversions.rb'
require 'pathname'
require 'date'
require 'fileutils'

# Default configuration: [min age, [weekday numbers to keep]]
# Second param overrides
default_rules = [
  [14, [1,3,5,7]],
  [30, [1,5]]
]

usage = <<EOS
Usage: thin-backups.rb <directory> [rules | '-'] [start-date]

Options:
  -h, --help                 This.
  -p, --pretend              Say what would be deleted but don't really delete.
  -q, --quiet                Print nothing.

EOS

dir = nil
pretend = false
quiet = false
rules = nil
initial_date = nil

while !ARGV.empty?
  arg = ARGV.shift
  if arg =~ /^-h|--help$/
    puts usage
    exit
  elsif arg =~ /^-p|--pretend$/
    pretend = true
  elsif arg =~ /^-q|--quiet$/
    quiet = true
  elsif dir == nil
    dir = arg
  elsif rules == nil
    if arg != '-' then rules = eval(arg) else rules = default_rules end
  elsif initial_date == nil
    initial_date = Date.parse(arg)
  end
end

if dir == nil
  puts usage
  exit 1
end

if rules == nil
  rules = default_rules
end

if initial_date == nil
  initial_date = Date.today
end

if pretend && !quiet
  puts "#{arg} given - won't actually do anything"
end


file_regex = /-(\d{4})(\d{2})(\d{2})\.tar\.(?:gz|bz2)$/

def monday_based_weekday(date)
  if date.wday == 0 then 7 else date.wday end
end

for file in Pathname(dir).children.sort
  if file.file? && file.basename.to_s =~ file_regex
    year, month, day = [$1, $2, $3].map(&:to_i)
    date = Date.new(year, month, day)
    age = (initial_date - date).to_i
    
    delete = false
    rules.each_index do |i|
      min_age, weekdays = rules[i]
      next_min_age = if rules[i+1] then rules[i+1][0] else 100000000000000 end
      if min_age <= age && age < next_min_age && !weekdays.include?(monday_based_weekday(date))
        delete = true
        break
      end
    end
    
    if delete
      puts "Deleting #{file}" unless quiet
      FileUtils.rm(file) unless pretend
    else
      puts "Leaving #{file}" unless quiet
    end
  end
end
