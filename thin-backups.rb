#!/usr/bin/env ruby
# Usage: thin-backups.rb <directory>
# Given a backup directory with files like foo-YYYYMMDD.tar.(gz|bz2),
# removes some backups that are older than the configured time(s).

require 'rubygems'
require 'active_support/all'
require 'pathname'
require 'date'
require 'fileutils'

# Default configuration: [min age, [weekday numbers to keep]]
# Second param overrides
default_rules = [
  [14, [1,3,5,7]],
  [30, [1,5]]
]

if ARGV.empty?
  echo "Usage: thin-backups.rb <directory> [rules | '-'] [start-date]"
  exit 1
end

dir = ARGV.shift

rules = ARGV.shift
if rules
  rules = eval(rules)
else
  rules = default_rules
end

initial_date = ARGV.shift
if initial_date
  initial_date = Date.parse(initial_date)
else
  initial_date = Date.today
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
      puts "Deleting #{file}"
      FileUtils.rm(file)
    else
      puts "Leaving #{file}"
    end
  end
end
