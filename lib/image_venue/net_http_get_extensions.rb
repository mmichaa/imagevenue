module ImageVenue
  module NetHttpGetExtensions
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
    end
  end
end

Net::HTTP::Get.send(:include, ImageVenue::NetHttpGetExtensions)