module Jekyll
  module Assets
    module Filters
      NAMES = %w[ asset_path ] + Tag::TAGS.keys + Tag::ALIAS.keys

      NAMES.each do |name|
        define_method name do |*args|
          Tag.send(:new, name, *args, []).render(@context)
        end
      end
    end
  end
end

Liquid::Template.register_filter Jekyll::Assets::Filters
