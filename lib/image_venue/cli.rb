require 'getoptlong'

module ImageVenue
  class Cli
    class << self
      def main
        cli = self.new
        cli.main
      end
    end

    attr_accessor :options
    attr_accessor :options_hash
    attr_accessor :command
    attr_accessor :arguments

    def initialize
      self.options = GetoptLong.new(
        ['-d', '--debug', GetoptLong::NO_ARGUMENT],
        ['-p', '--password', GetoptLong::REQUIRED_ARGUMENT],
        ['-u', '--username', GetoptLong::REQUIRED_ARGUMENT]
      )
      self.options_hash = {}
      self.options.each do |option, argument|
        self.options_hash[option] = argument
      end
      self.command = ARGV.shift
      self.arguments = ARGV.clone
      return nil
    end

    def main
      ImageVenue.debug = self.options_hash.has_key?('-d')

      if self.command.nil? or self.command.empty?
        puts "USAGE: #{$0} -u <USERNAME> -p <PASSWORD> <COMMAND> [<ARGUMENT>]"
        return false
      else
        command_block = nil
        self.command = self.command.to_sym

        if self.command == :list
          command_block = lambda do |connection|
            connection.directories.each do |directory|
              puts directory.name
            end
          end

        elsif self.command == :files
          directory_name = self.arguments.shift
          unless directory_name.nil? or directory_name.empty?
            command_block = lambda do |connection|
              directory = connection.directories.find {|dir| dir.name == directory_name}
              if directory
                directory.files.each do |file|
                  puts file.real_name
                end
              else
                puts "NOT_FOUND_ERROR"
              end
            end
          end

        elsif self.command == :create
          directory_name = self.arguments.shift
          unless directory_name.nil? or directory_name.empty?
            command_block = lambda do |connection|
              directory = ImageVenue::Directory.new(connection, directory_name)
              if directory.save
                puts "OK"
              else
                puts "ERROR"
              end
            end
          end

        elsif self.command == :upload
          directory_name = self.arguments.shift
          filepathes = self.arguments
          unless directory_name.nil? or directory_name.empty? or filepathes.nil? or filepathes.empty?
            command_block = lambda do |connection|
              directory = connection.directories.find {|dir| dir.name == directory_name}
              if directory
                directory.select
                filepathes.each do |filepath|
                  file = ImageVenue::File.new(directory, filepath)
                  if file.save
                    puts "OK #{filepath}"
                  else
                    puts "ERROR #{filepath}"
                  end
                end
              else
              end
            end
          end

        elsif self.command == :delete
          directory_name = self.arguments.shift
          unless directory_name.nil? or directory_name.empty?
            command_block = lambda do |connection|
              directory = connection.directories.find {|dir| dir.name == directory_name}
              if directory
                if directory.destroy
                  puts "OK"
                else
                  puts "ERROR"
                end
              else
                puts "NOT_FOUND_ERROR"
              end
            end
          end
        end

        if command_block
          ImageVenue.login(options_hash['-u'], options_hash['-p']) do |connection|
            command_block.call(connection)
            connection.logout
          end
        end
      end
    end
  end
end
