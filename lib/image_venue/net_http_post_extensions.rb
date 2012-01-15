# Multipart POST file upload for Net::HTTP::Post.
#
# By Leonardo Boiko <leoboiko@gmail.com>, public domain.
# By Michael Nowak <thexsystem@web.de>, public domain.
#
# Usage: see documentation for Net::HTTP::Post#set_multipart_data.

require 'fileutils' unless defined?(FileUtils)

module ImageVenue
  module NetHttpPostExtensions
    def self.included(base)
      base.send(:extend, ClassMethods)
      base.send(:include, InstanceMethods)
      base.class_eval do
        attr_accessor :header
      end
      return nil
    end

    module ClassMethods
    end

    module InstanceMethods
      # Similar to Net::HTTP::Post#set_form_data (in Ruby's stardard
      # library), but set up file upload parameters using the
      # appropriate HTTP/HTML Forms multipart format.
      #
      # *Arguments*
      #
      # files_params:: A hash of file upload parameters.  The keys are
      #                parameter names, and the values are
      #                Net::HTTP::FileForPost instances.  See that
      #                class documentation for more info about how
      #                POST file upload works.
      #
      # other_params:: A hash of {key => value} pairs for the regular
      #                POST parameters, just like in set_form_data.
      #                Don't mix set_form_data and set_multipart_data;
      #                they'll overwrite each other's work.
      #
      # boundary1, boundary2:: A couple of strings which doesn't occur
      #                        in your files.  Boundary2 is only
      #                        needed if you're using the
      #                        multipart/mixed technique.  The
      #                        defaults should be OK for most cases.
      #
      # *Examples*
      #
      # Simplest case (single-parameter single-file), complete:
      #
      #   require 'net/http'
      #   require 'net_http_post_extensions'
      #
      #   req = Net::HTTP::Post.new('/scripts/upload.rb')
      #   req.basic_auth('jack', 'inflamed sense of rejection')
      #
      #   file = Net::HTTP::FileForPost.new('/body/yourlife.txt', 'text/plain')
      #   req.set_multipart_data({:poem => file},
      #
      #                          {:author => 'jack',
      #                            :user_agent => 'soapfactory'})
      #
      #   res = Net::HTTP.new(url.host, url.port).start do |http|
      #     http.request(req)
      #   end
      #
      # Convoluted example:
      #
      #   pic1 = Net::HTTP::FileForPost.new('pic1.jpeg', 'image/jpeg')
      #   pic2 = Net::HTTP::FileForPost.new(pic2_io, 'image/jpeg')
      #   pic3 = Net::HTTP::FileForPost.new('pic3.png', 'image/png')
      #   pic1_t = Net::HTTP::FileForPost.new('pic1_thumb.jpeg', 'image/jpeg')
      #   pic2_t = Net::HTTP::FileForPost.new(pic2_t_io, 'image/jpeg')
      #   desc = Net::HTTP::FileForPost.new('desc.html', 'text/html',
      #                                      'index.html') # remote fname
      #
      #   req.set_multipart_data({:gallery_description => des,
      #                           :pictures => [pic1, pic2, pic3],
      #                           :thumbnails => [pic1_t, pic2_t]},
      #
      #                          {:gallery_name => 'mygallery',
      #                           :encoding => 'utf-8'})
      #
      def set_multipart_data(files_params, other_params={}, boundary1='paranguaricutirimirruaru0xdeadbeef', boundary2='paranguaricutirimirruaru0x20132')
        self.content_type = "multipart/form-data; boundary=\"#{boundary1}\""

        body = StringIO.new('r+b')

        # let's do the easy ones first
        other_params.each do |key, value|
          body.write "--#{boundary1}\r\n"
          body.write "content-disposition: form-data; name=\"#{key}\"\r\n"
          body.write "\r\n"
          body.write "#{value}\r\n"
        end

        # now handle the files...
        files_params.each do |name, file_or_files|
          files = [file_or_files].flatten

          if name.to_s =~ /\[\]$/
            files.each do |file|
              body.write "\r\n--#{boundary1}\r\n"
              body.write "content-disposition: form-data; name=\"#{name}\"; filename=\"#{file.base_name}\"\r\n"
              # single-file multipart is different
              body.write "Content-Type: #{file.content_type}\r\n"
              body.write "Content-Transfer-Encoding: binary\r\n"
              body.write "\r\n"
              FileUtils.copy_stream(Kernel::File.open(file.name, 'rb'), body)
            end
          else
            body.write "\r\n--#{boundary1}\r\n"
            body.write "content-disposition: form-data; name=\"#{name}\""
            # multiple-file parameter (multipart/mixed)
            body.write "\r\n"
            body.write "Content-Type: multipart/mixed;"
            body.write " boundary=\"#{boundary2}\"\r\n"

            files.each do |file|
              body.write "\r\n--#{boundary2}\r\n"
              body.write "Content-disposition: attachment"
              body.write "; filename=\"#{file.base_name}\"\r\n"
              body.write "Content-Type: #{file.content_type}\r\n"
              body.write "Content-Transfer-Encoding: binary\r\n"
              body.write "\r\n"
              FileUtils.copy_stream(Kernel::File.open(file.name, 'rb'), body)
            end
            body.write "\r\n--#{boundary2}--\r\n"
          end
        end
        body.write "--#{boundary1}--\r\n"

        body.flush
        self.content_length = body.size
        self.body_stream = body
        self.body_stream.rewind
        return true
      end
    end
  end
end

Net::HTTP::Post.send(:include, ImageVenue::NetHttpPostExtensions)