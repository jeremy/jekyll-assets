require 'rspec/helper'

describe Jekyll::Assets::Filters do
  let(:renderer) { Renderer.new stub_jekyll_site }

  [ %w( img ruby.png ), %w( image ruby.png ),
    %w( js bundle ),    %w( javascript bundle ),
    %w( css bundle ),   %w( stylesheet bundle ),
    %w( asset_path bundle.css)
  ].each do |name, *args|
    context "#{name} filter" do
      it "matches the #{name} tag" do
        expect(renderer.filter(name, *args)).to eq renderer.tag(name, *args)
      end
    end
  end

  class Renderer
    include Jekyll::Assets::Filters
    def initialize(site, options = {})
      @site = site
      @sprockets = Jekyll::Assets::Env.new(@site)
      @context = Liquid::Context.new({}, {}, { :site => @site, :sprockets => @sprockets })
    end

    def filter(name, *args)
      public_send name, *args
    end

    def tag(name, *args)
      Jekyll::Assets::Tag.send(:new, name, *args, []).render(@context)
    end
  end
end
