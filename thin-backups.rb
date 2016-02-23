#!/usr/bin/env ruby

require 'rubygems'
require 'active_support/core_ext/date/conversions.rb'
require 'pathname'
require 'date'
require 'fileutils'

default_rules = ["14:1,3,5,7", "30:1,5"] # also change description below if you change this

usage = <<EOS
Usage: thin-backups.rb [options] <directory> [rules]

  Removes old backups from a directory with files or subdirectories whose
  names contain a date in YYYYMMDD format. For example, a file
  'foo-20120519.tar.gz' or a directory named just '20120519' are recognized.

  It can be given rules of the form min_age:weekday_numbers
  where weekday numbers are separated by commas.
  Consider the following default rules:

  #{default_rules.join(' ')}

  this means that for all backups that are at least 14 days old,
  we only keep backups from mondays, wednesdays, fridays and sundays,
  and for all backups at least 30 days old, only keep the ones
  from mondays and fridays. We could also add '180:' to delete backups older
  than 180 days.

Options:
  -h, --help                 This.
  -p, --pretend              Say what would be deleted but don't really delete.
  -q, --quiet                Print nothing.
  -s, --start-date YYYYMMDD  Only process files older than the given date.

EOS

$rule_regex = /^(\d+):(\d+(?:,\d+)*)?$/

# Parses a rule into [min_age, [weekdays*]]
def parse_rule(rule_str)
  if rule_str =~ $rule_regex
    min_age = $1.to_i
    weekdays = $2.to_s.split(",").map(&:to_i)
    [min_age, weekdays]
  else
    raise "Could not parse rule: #{rule_str}"
  end
end

dir = nil
pretend = false
quiet = false
rules = []
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
  elsif arg =~ /^-s|--start-date$/
    initial_date = Date.parse(ARGV.shift)
  elsif dir == nil
    dir = arg
  elsif arg =~ $rule_regex
    rules << parse_rule(arg)
  end
end

if dir == nil
  puts usage
  exit 1
end

if rules.empty?
  rules = default_rules.map {|r| parse_rule(r) }
end

if initial_date == nil
  initial_date = Date.today
end

if pretend && !quiet
  puts "--pretend given - won't actually do anything"
end


file_regex = /^(?:.*\D)?(\d{4})(\d{2})(\d{2})(?:\D.*)?$/

def monday_based_weekday(date)
  if date.wday == 0 then 7 else date.wday end
end

for file in Pathname(dir).children.sort
  if file.basename.to_s =~ file_regex
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
      FileUtils.rm_rf(file) unless pretend
    else
      puts "Leaving #{file}" unless quiet
    end
  end
end
