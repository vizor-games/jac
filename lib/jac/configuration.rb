require 'yaml'
require 'ostruct'

module Jac
  # Configuration is loaded from well formed YAML streams.
  # Each document expected to be key-value mapping where
  # keys a `profile` names and values is a profile content.
  # Profile itself is key-value mapping too. Except reserved
  # key names (i.e. `extends`) each key in profile is a
  # configuration field. For example following yaml document
  #
  # ```yml
  #
  #  foo:
  #    bar: 42
  #  qoo:
  #    bar: 32
  #
  # ```
  #
  # represents description of two profiles, `foo` and `qoo`,
  # where field `bar` is set to `42` and `32` respectively.
  #
  # Profile can be constructed using combination of other profiles
  # for example having `debug` and `release` profiles for testing
  # and production. And having `remote` and `local` profiles for
  # building on local or remote machine. We cant get `debug,local`,
  # `debug,remote`, `release,local` and `release,remote` profiles.
  # Each of such profiles is a result of merging values of listed
  # profiles. When merging profile with another configuration
  # resolver overwrites existing fields. For example if `debug`
  # and `local` for some reason have same field. In profile
  # `debug,local` value from `debug` profile will be overwritten
  # with value from `local` profile.
  #
  # ## Extending profiles
  #
  # One profile can `extend` another. Or any amount of other
  # profiles. To specify this one should use `extends` field
  # like that
  #
  # ```yml
  #
  # base:
  #   application_name: my-awesome-app
  #   port: 80
  #
  # version:
  #   version_name: 0.0.0
  #   version_code: 42
  #
  # debug:
  #   extends: [base, version]
  #   port: 9292
  # ```
  #
  # In this example `debug` will receive following fields:
  #
  # ```yml
  # application_name: my-awesome-app  # from base profile
  # port: 9292                        # from debug profile
  # version_name: 0.0.0               # from version profile
  # version_code: 42                  # from version profile
  # ```
  #
  # ## Merging multiple configuration files
  #
  # Configuration can be loaded from multiple YAML documents.
  # Before resolve requested profile all described profiles
  # are merged down together. Having sequence of files like
  # `.application.yml`, `.application.user.yml` with following content
  #
  # ```yml
  # # .application.yml
  # base:
  #   user: deployer
  #
  # debug:
  #   extends: base
  #   # ... other values
  # ```
  #
  # ```yml
  # # .application.user.yml
  # base:
  #  user: developer
  # ```
  #
  # We'll get `user` field overwritten with value from
  # `.application.user.yml`. And only after that construction
  # of resulting profile will begin (for example `debug`)
  #
  # ## String evaluation
  #
  # Configuration resolver comes with powerful yet dangerous
  # feature: it allows evaluate strings as ruby expressions
  # like this:
  #
  # ```yml
  # foo:
  #   build_time: "#{Time.now}" # Will be evaluated at configuration resolving step
  # ```
  #
  # Configuration values are available to and can be referenced with `c`:
  #
  # ```yml
  # base:
  #   application_name: my-awesome-app
  # debug:
  #   extends: base
  #   server_name: "#{c.application_name}-debug"   # yields to my-awesome-app-debug
  # release:
  #   extends: base
  #   server_name: "#{c.application_name}-release" # yields to my-awesome-app-release
  # ```
  #
  # All strings evaluated **after** profile is constructed thus
  # you don't need to have declared values in current profile
  # but be ready to get `nil`.
  #
  # ## Merging values
  #
  # By default if one value have multiple defenitions it will be overwritten by
  # topmost value. Except several cases where Jac handles value resolution
  # specialy
  #
  # ### Merging hashes
  #
  # Hashes inside profile are recurseively merged automaticly. This rule works
  # for profile extensions and value redefenitions too.
  #
  # Example:
  #
  # ```yml
  # base:
  #   servers:
  #     release: http://release.com
  #
  # debug:
  #   extends: base
  #     debug: http://debug.com
  #
  # ```
  #
  # ### Merging sets
  #
  # Sets allowed to be merged with `nil`s and any instance of `Enumerable`.
  # Merge result is always new `Set` instance.
  # ```yml
  # release:
  #   extends:
  #     - no_rtti
  #     - no_debug
  #   flags: !set {} # empty set
  # no_rtti:
  #   flags:
  #     - -fno-rtti
  # no_debug:
  #   flags:
  #     - -DNDEBUG
  # ```
  #
  # Resulting profile will have `-fno-rtti, -DNDEBUG` in `release profile`
  # ## Generic profiles
  #
  # Same result as shown above can be achieved with generic profiles. Generic profile
  # is a profile which name is regex (i.e. contained in `/.../`):
  #
  # ```
  # base:
  #   application_name: my-awesome-app
  # /(release|debug)/: # Profile name is a regex, with single capture (1)
  #   extends: base
  #   server_name: "#{c.application_name}-#{c.captures[1]}"  # yields  my-awesome-app-release or  my-awesome-app-debug
  # ```
  #
  # If profile name matches multiple generic profiles it not defined
  # which profile will be used.
  module Configuration
    # Reads and evaluates configuration for given set of streams
    # and profile
    class ConfigurationReader
      # Any configuration set always contains `default` profile
      # which is loaded when no profile requested.
      DEFAULT_PROFILE_NAME = 'default'.freeze
      # Creates "empty" config
      DEFAULT_CONFIGURATION = -> () { { DEFAULT_PROFILE_NAME => {} } }
      attr_reader :merger
      # Creates configuration reader
      # @param [Array] streams of pairs containing YAML document and provided
      #   name for this stream
      def initialize(streams)
        @streams = streams
        @merger = Merger.new
      end

      # Parses all streams and resolves requested profile
      # @param [Array] profile list of profile names to be merged
      # @return [OpenStruct] instance which contains all resolved profile fields
      def read(*profile)
        result = @streams
                 .flat_map { |stream, _name| read_stream(stream) }
                 .inject(DEFAULT_CONFIGURATION.call) { |acc, elem| update(acc, elem) }
        OpenStruct.new(evaluate(resolve(profile, result)).merge('profile' => profile))
      end

      private

      def read_stream(stream)
        # Each stream consists of one or more documents
        YAML.parse_stream(stream).children.flat_map do |document|
          # Will use separate visitor per YAML document.
          visitor = Jac::Parser::VisitorToRuby.create
          # Expecting document to be single mapping
          profile_mapping = document.children.first
          raise(ArgumentError, 'Mapping expected') unless profile_mapping.is_a? Psych::Nodes::Mapping
          # Then mapping should be expanded to (key, value) pairs. Because yaml overwrites
          # values for duplicated keys. This is not desired behaviour. We need to merge
          # such entries
          profile_mapping
            .children
            .each_slice(2)
            .map { |k, v| { visitor.accept(k) => visitor.accept(v) } }
        end
      end

      def update(config, config_part)
        config_part.each do |profile, values|
          profile_values = config[profile]
          unless profile_values
            profile_values = {}
            config[profile] = profile_values
          end
          merge!(profile_values, values)
        end

        config
      end

      # Merges two hash structures using following rules
      # @param [Hash] base value mappings
      # @param [Hash] values ovverides.
      # @return [Hash] merged profile
      def merge!(base, values)
        merger.merge!(base, values)
      end

      def resolve(profile, config)
        ProfileResolver.new(config).resolve(profile)
      end

      def evaluate(resolved_profile)
        ConfigurationEvaluator.evaluate(resolved_profile)
      end
    end

    # Describes profile resolving strategy
    class ProfileResolver
      # Key where all inherited profiles listed
      EXTENDS_KEY = 'extends'.freeze

      attr_reader :config, :merger

      def initialize(config)
        @config = config
        @merger = Merger.new
      end

      def resolve(profile, resolved = [])
        profile.inject({}) do |acc, elem|
          if resolved.include?(elem)
            msg = 'Cyclic dependency found ' + (resolved + [elem]).join(' -> ')
            raise(ArgumentError, msg)
          end
          profile_values = find_profile(elem)
          # Find all inheritors
          extends = *profile_values[EXTENDS_KEY] || []
          # We can do not check extends. Empty profile returns {}
          # Inherited values goes first
          inherited = merger.merge(acc, resolve(extends, resolved + [elem]))
          merger.merge(inherited, profile_values)
        end
      end

      def find_profile(profile_name)
        return config[profile_name] if config.key?(profile_name)
        # First and last chars are '/'
        match, matched_profile = find_generic_profile(profile_name)
        # Generating profile
        return generate_profile(match, matched_profile, profile_name) if match
        raise(ArgumentError, 'No such profile ' + profile_name)
      end

      def generate_profile(match, matched_profile, profile_name)
        gen_profile = {}
        gen_profile['captures'] = match.captures if match.captures
        if match.respond_to?(:named_captures) && match.named_captures
          gen_profile['named_captures'] = match.named_captures
        end
        gen_profile.merge!(config[matched_profile])

        config[profile_name] = gen_profile
      end

      # @todo print warning if other matching generic profiles found
      def find_generic_profile(profile_name)
        generic_profiles(config)
          .detect do |profile, regex|
            m = regex.match(profile_name)
            break [m, profile] if m
          end
      end

      def generic_profiles(config)
        # Create generic profiles if missing
        @generic_profiles ||= config
                              .keys
                              .select { |k| k[0] == '/' && k[-1] == '/' }
                              .map { |k| [k, Regexp.new(k[1..-2])] }

        @generic_profiles
      end
    end

    # Proxy class for getting actual values
    # when referencing profile inside evaluated
    # expressions
    class EvaluationContext
      def initialize(evaluator)
        @evaluator = evaluator
      end

      def respond_to_missing?(_meth, _args, &_block)
        true
      end

      def method_missing(meth, *args, &block)
        # rubocop ispection hack
        return super unless respond_to_missing?(meth, args, &block)
        @evaluator.evaluate(meth.to_s)
      end
    end

    # Evaluates all strings inside resolved profile
    # object
    class ConfigurationEvaluator
      def initialize(src_object, dst_object)
        @object = src_object
        @evaluated = dst_object
        @context = EvaluationContext.new(self)
        resolve_object
      end

      def evaluate(key)
        return @evaluated[key] if @evaluated.key? key
        @evaluated[key] = evaluate_deep(@object[key])
      end

      def c
        @context
      end

      alias config c
      alias conf c
      alias cfg c

      private

      def resolve_object
        @object.each_key { |k| evaluate(k) }
        # Cleanup accidentally created values (when referencing missing values)
        @evaluated.delete_if { |k, _v| !@object.key?(k) }
      end

      def get_binding(obj)
        binding
      end

      def evaluate_deep(object)
        case object
        when String
          eval_string(object)
        when Array
          object.map { |e| evaluate_deep(e) }
        when Hash
          # Evaluating values only by convention
          object.inject({}) { |acc, elem| acc.update(elem.first => evaluate_deep(elem.last)) }
        else
          object
        end
      end

      def eval_string(o)
        evaluated = /#\{.+?\}/.match(o) do
          eval('"' + o + '"', get_binding(self))
        end

        evaluated || o
      end

      class << self
        def evaluate(o)
          dst = {}
          ConfigurationEvaluator.new(o, dst)
          dst
        end
      end
    end

    # List of files where configuration can be placed
    # * `jac.yml` - expected to be main configuration file.
    # Usually it placed under version control.
    # * `jac.user.yml` - user defined overrides for main
    # configuration, sensitive data which can't be placed
    # under version control.
    # * `jac.override.yml` - final overrides.
    CONFIGURATION_FILES = %w[jac.yml jac.user.yml jac.override.yml].freeze

    class << self
      # Generates configuration object for given profile
      # and list of streams with YAML document
      # @param profile [Array] list of profile names to merge
      # @param streams [Array] list of YAML documents and their
      # names to read
      # @return [OpenStruct] instance which contains all resolved profile fields
      def read(profile, *streams)
        profile = [ConfigurationReader::DEFAULT_PROFILE_NAME] if profile.empty?
        ConfigurationReader.new(streams).read(*profile)
      end

      # Read configuration from configuration files.
      def load(profile, files: CONFIGURATION_FILES, dir: Dir.pwd)
        # Read all known files
        streams = files
                  .map { |f| [File.join(dir, f), f] }
                  .select { |path, _name| File.exist?(path) }
                  .map { |path, name| [IO.read(path), name] }
        read(profile, *streams)
      end
    end
  end
end
