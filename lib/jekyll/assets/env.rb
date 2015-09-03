require_relative "logger"
require_relative "configuration"
require_relative "context"
require_relative "cached"

module Jekyll
  module Assets
    class Env < Sprockets::Environment
      attr_reader :jekyll, :used
      class << self
        attr_accessor :digest_cache, :assets_cache
        def digest_cache
          @_digest_cache ||= \
            {}
        end
      end

      def initialize(path, jekyll = nil)
        jekyll, path = path, nil if path.is_a?(Jekyll::Site)
        @used, @jekyll = Set.new, jekyll
        path ? super(path) : super()
        disable_erb

        jekyll.config["assets"] = Configuration.merge(asset_config)
        private_methods(false).select { |v| v =~ %r!\Asetup_! }.map { |v| send(v) }
        Hook.trigger :env, :post_init, self
        jekyll.sprockets = self
      end

      def in_cache_dir(*paths)
        paths.reduce(@cache_dir) do |base, path|
          Jekyll.sanitized_path(base, path)
        end
      end

      def cached_write?
        !@used.any?
      end

      def all_assets(cached = false)
        if !cached
          then Set.new(@used).merge extra_assets
          else Set.new(self.class.assets_cache).merge extra_assets
        end
      end

      def extra_assets
        each_logical_path(*asset_config.fetch("assets", [])).map do |v|
          find_asset v
        end
      end

      def cdn?() !dev? && !!asset_config["cdn"] end
      def dev?() %W(development test).include? Jekyll.env end
      def compress?(what) !!asset_config["compress"][what] end
      def asset_config() jekyll.config["assets"] ||= {} end
      def digest?() !!asset_config["digest"] end
      def prefix() asset_config["prefix"] end

      def prefix_path(path = nil)
        prefix = cdn? && asset_config["skip_prefix_with_cdn"] ? "" : self.prefix
        if cdn? && (cdn = asset_config["cdn"])
          return File.join(cdn, prefix) if !path
          File.join(cdn, prefix, path)
        else
          return prefix if !path
          File.join(prefix, path)
        end
      end

      def cached
        Cached.new(self)
      end

      def write_all
        if cached_write?
          then write_cached_assets else write_assets
        end
      end

      private
      def write_assets(assets = self.all_assets)
        self.class.assets_cache = assets
        self.class.digest_cache = Hash[assets.map do |a|
          [a.logical_path, a.digest]
        end]

        assets.each do |v|
          v.write_to as_path v
        end
      end

      private
      def write_cached_assets(assets = all_assets(true))
        assets.each do |a|
          if !a.is_a?(Tag::ProxiedAsset)
            viejo = self.class.digest_cache[a.logical_path]
            nuevo = find_asset(a.logical_path).digest
            path  = as_path a

            if nuevo == viejo && File.file?(path)
              next
            end
          else
            if File.file?(a.logical_path)
              next
            end
          end

          self.class.digest_cache[a.logical_path] = a.digest
          a.write_to as_path a
        end
      end

      private
      def as_path(v)
        path = digest?? v.digest_path : v.logical_path
        jekyll.in_dest_dir(File.join(prefix, path))
      end

      def disable_erb
        self.config = hash_reassoc(config, :engines) do |h|
          h.delete(".erb")
        h
        end
      end

      private
      def setup_css_compressor
        if compress?("css")
          self.css_compressor = :sass
        end
      end

      private
      def setup_js_compressor
        if compress?("js")
          Helpers.try_require "uglifier" do
            self.js_compressor = :uglify
          end
        end
      end

      private
      def setup_context
        Context.new(context_class)
      end

      private
      def setup_version
        self.version = Digest::MD5.hexdigest \
          jekyll.config.fetch("assets", {}).to_s
      end

      private
      def setup_sources
        asset_config["sources"].each do |v|
          append_path jekyll.in_source_dir(v)
        end
      end

      private
      def setup_logger
        self.logger = Logger.new
      end

      private
      def setup_cache
        if @cache_dir = asset_config.fetch("cache", ".asset-cache")
          self.cache = Sprockets::Cache::FileStore.new @cache_dir
        end
      end
    end
  end
end
