
module Strings
  extend self

  def unindent(s)
    lines = s.lines
    lines.reject! {|line| line.chars.all? {|c| c == ' ' } }
    spaces = lines.map {|line| line.length - line.lstrip.length }.min
    lines.map! {|line| line[spaces..-1] }
    lines.join
  end
end
