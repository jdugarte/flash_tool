require 'tempfile'
require File.dirname(__FILE__) + '/flash_tool/flash_script.rb'
require File.dirname(__FILE__) + '/flash_tool/flash_object.rb'
require File.dirname(__FILE__) + '/flash_tool/flash.rb'
require File.dirname(__FILE__) + '/flash_tool/flash_combine.rb'
require 'cocaine'

module FlashTool
  class FlashToolError < RuntimeError
  end

  # This class provides usefull utilities for getting informations from flash files
  # ===<b>Important</b>
  # Method FlashTool.text and options FlashTool.method_missing("text", "file") and
  # swfdump("file","text") on same system don't work appropriate instead use method <b>parse_text</b>
  #
  class FlashTool
    class <<self
      # This method parse text from swf file.
      # File must have extension swf
      def parse_text(file)
        # something is bad with this program don't send errors, and we must check for errors
        # we must check file first
        # by documetation swfdump --text need to do this but
        raise FlashToolError, "File missing path: #{file}" unless File.exist?(file)
        raise FlashToolError, "Wrong file type SWF path: #{file} "  unless file =~ /(.swf)$/i
        line = Cocaine::CommandLine.new("swfstrings", ":file")
        line.command({ :file => file })
        output = line.run rescue raise(FlashToolError)
        return output
      end



      # Call swfdump commands in shorter way
      # Can be used any option from  swfdump command
      # in casess: width, heihght and frames returns Integer
      # in case rate returns Float
      # in all other casess retruns String
      #
      def method_missing(option, file)
        text = self.swfdump(file, option)
        option = option.to_s
        if option == "width" || option == 'height' || option == 'frames'
          return text.split(' ').last.to_i
        elsif option == 'rate'
          return text.split(' ').last.to_f
        else
          return text
        end
      end

      ###
      # Returns hash value with basic flash parameters
      # Keys are [width, rate, height, frames] and
      # values are kind of string
      def flash_info(file)
        args = ['width', 'rate', 'height', 'frames']
        data = swfdump(file, args)
        data.gsub!(/(-X)/, "width ")
        data.gsub!(/(-Y)/, "height ")
        data.gsub!(/(-r)/, "rate ")
        data.gsub!(/(-f)/, "frames ")

        return Hash[*data.split(' ')]

      end


      ###
      # This  method is very similar to swfdump command http://www.swftools.org/swfdump.html
      # Use longer options for this commands without --
      # DON'T use option text that option don't work
      # ===Examples
      #  FlashTool.swfdump('test.swf', 'rate')
      #
      #  FlashTool.swfdump('test.swf', ['rate','width','height'])
      def swfdump(file, options=nil)
        options = [options].flatten.compact.map(&:to_s)
        arguments = {}
        options.each { |option| arguments[option.to_sym] = option }
        options_list = arguments.keys.map { |k| "--:#{k}"}.join(' ')
        line = Cocaine::CommandLine.new("swfdump", "#{options_list} :file")
        line.command(arguments.merge({ :file => file }))
        line.run
      rescue Cocaine::ExitStatusError => e
        raise FlashToolError, e.message
      end
    end

  end
end


