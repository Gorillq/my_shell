#!/usr/bin/env ruby

require 'open3'
require 'benchmark'

module Colorize
  COLOURS = {
    red: "\e[31m",
    green: "\e[32m",
    yellow: "\e[33m",
    blue: "\e[34m",
    lblue: "\e[0;94m",
    teal: "\e[0;96m",
    reset: "\e[0m"
  }

  def colorize(colour, input)
    output = "#{COLOURS[colour]}#{input}#{COLOURS[:reset]}"
    output.strip
  end
end

class Param
  def self.sanitize(prompt)
    prompt.insert(0, "'")
    prompt.insert(prompt.size, "'")
    prompt
  end

  def self.cd_handle(arg)
    #change directory
    if arg.length == 2
      Dir.chdir(arg[1])
      puts "Changed dir to #{Dir.pwd}"
    else
      puts "Usage: cd <dir>"
    end
  rescue Errno::ENOENT
    p "Directory not found: #{arg[1]}"
  rescue Errno::EACCES
    p "Permission denied: #{arg[1]}"
  end

  def self.chdir?(arg)
    arg[0] == "cd"
  end

  def self.check(array)
    if chdir?(array)
      cd_handle(array)
      return
    end

    begin
      stdout, stderr, status = Open3.capture3(*array.map(&:to_s))
    rescue Errno::ENOENT
      p "Failed. Invalid command?"
      return
    else
      if stdout == ""
        command = array.map(&:to_s)
        sanitize(command)
        sanitized = "bash -c " << command.join
        system(sanitized)
      end
    end
    puts status.success? ? stdout : "Failed: #{stderr}"
  end
end

class Shella < Param
  include Colorize

  def initialize(*args)
    super
  end

  def userhost
    username = `whoami`.strip
    hostname = `uname -n`.strip
    return username, hostname
  end

  def print_user(user, host)
    at = colorize(:red, "@")
    dollar = colorize(:red, "$: ")
    o_bracket = colorize(:green, "[")
    b_bracket = colorize(:green, "]")
    print o_bracket << user << at.strip << host << b_bracket << dollar
  end

  def prompt_methods(input)
    input.split.map(&:to_s)
  end

  def shell_logic
    loop do
      get_user, get_host = userhost
      user = colorize(:lblue, get_user)
      host = colorize(:teal, get_host)
      print_user(user, host)
      tmp = gets.chomp
      args = prompt_methods(tmp)

      # Benchmark the Param.check method
      time = Benchmark.measure do
        Param.check(args)
      end
      puts "Param.check execution time: #{time.real} seconds"
    end
  end
end

if __FILE__ == $0
  # Benchmark the shell_logic method
  time = Benchmark.measure do
    Shella.new.shell_logic
  end
  puts "Shella.shell_logic total execution time: #{time.real} seconds"
end
