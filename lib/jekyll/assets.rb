require "sprockets"
require "sprockets/helpers"
require "jekyll"

require_relative "assets/hook"
require_relative "assets/helpers"
require_relative "assets/extras/es6"
require_relative "assets/extras/helpers"
require_relative "assets/extras/prefix"

require_relative "assets/env"
require_relative "assets/patches/jekyll/cleaner"
require_relative "assets/patches/sprockets/asset"
require_relative "assets/patches/jekyll/site"

require_relative "assets/hooks/post_read"
require_relative "assets/hooks/post_write"
require_relative "assets/tag"
require_relative "assets/filters"
