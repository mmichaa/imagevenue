require 'cgi' unless defined?(CGI::Cookie)
require 'net/http' unless defined?(Net::HTTP)
require 'image_venue/net_http_get_extensions' unless defined?(NetHttpGetExtensions)
require 'image_venue/net_http_post_extensions' unless defined?(NetHttpPostExtensions)
require 'open-uri' unless defined?(OpenURI)
require 'uri' unless defined?(URI)
require 'rubygems' unless defined?(Gem)
require 'hpricot' unless defined?(Hpricot)

Kernel_File = File
module Kernel
  class File < Kernel_File
  end
end

module ImageVenue
  class << self
    attr_accessor :debug

    def debug?
      (self.debug) ? true : false
    end

    def puts_debug(*args)
      if self.debug?
        puts(*args)
        return true
      else
        return false
      end
    end

    def base_url
      @base_url ||= 'http://users.imagevenue.com'
    end

    def base_uri
      @base_uri ||= URI.parse(self.base_url)
    end

    def version
      @version ||= [0, 0, 3]
    end

    def login(username, password, &block)
      connection = ImageVenue::Connection.new(username, password)
      if connection.login
        block.call(connection) if block_given?
      end
      return connection
    end
  end
end

require 'image_venue/connection'
require 'image_venue/directory'
require 'image_venue/file'