
# Methods either return an error or throw :cancel if Ctrl+D'ed or cancel selected.
module Prompts
  extend self

  def file_prompt(question, default = nil, &validate)
    Readline.completion_proc = Readline::FILENAME_COMPLETION_PROC
    prompt(question, default, &validate)
  end

  def prompt(question, default = nil, &validate)
    puts
    while true
      result = ""
      if default == nil
        while result.empty?
          result = Readline.readline("#{question} > ", false)
          throw :cancel if result == nil
        end
      else
        result = Readline.readline("#{question} [#{default}] > ", false)
        throw :cancel if result == nil
        result = default if result.empty?
      end

      if !validate || validate.call(result)
        break result
      end
    end
  end

  def yesno(question, default = nil)
    if default != nil
      default = if default then 'y' else 'n' end
    end
    answer = prompt("#{question} (y/n)", default) do |answer|
      ['y', 'n'].include?(answer.downcase)
    end
    answer == 'y'
  end

  def multiselect(question, choices, &choice_text_func)
    raise "choices must be a hash or an array" unless choices.is_a?(Hash) || choices.is_a?(Array)

    choice_keys = if choices.is_a?(Hash) then choices.keys else choices end
    choice_texts = if choices.is_a?(Hash) then choices.values else choices end
    if choice_text_func
      choice_texts = choice_texts.map(&choice_text_func)
    end

    puts
    while true
      puts question
      choice_texts.each_with_index do |c, i|
        puts "  [#{i + 1}] #{c}"
      end
      choice = Readline.readline("> ")
      throw :cancel if choice == nil
      choice = choice.to_i
      choice -= 1
      if (0...choices.size).include?(choice)
        break choice_keys[choice]
      end
    end
  end
end
