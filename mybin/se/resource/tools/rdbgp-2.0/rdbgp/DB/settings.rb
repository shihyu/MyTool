# - settings.rb
#
# Cloneable sets of settings
# We can do something like reference the debugger's object,
# and then get our own when they're about to be modified -- copy-on-write?
#
# This takes experimentation, so for now we'll create an instance
# of this class and peel things off

module Debugger

  module DBGP
  
  class Settings

    attr_reader :supportedCommands, :supportedFeatures

    def initialize
      @supportedCommands = {
      'status' => 1,
      'feature_get' => 1,
      'feature_set' => 1,
      'run' => 1,
      'step_into' => 1,
      'step_over' => 1,
      'step_out' => 1,
      'stop' => 1,
      'detach' => 1,
      'breakpoint_set' => 1,
      'breakpoint_get' => 1,
      'breakpoint_update' => 1,
      'breakpoint_remove' =>1,
      'breakpoint_list' => 1,
      'stack_depth' => 1,
      'stack_get' => 1,
      'context_names' => 1,
      'context_get' => 1,
      'typemap_get' => 1,
      'property_get' => 1,
      'property_set' => 1,
      'property_value' => 1,
      'source' => 1,
      'stdout' => 1,
      'stderr' => 1,
      'stdin' => 0,
      'break' => 1,
      'eval' => 0,
      'interact' => 1,
    }
          
    # Feature name => [bool(3): is supported, is settable, has associated value]
    @supportedFeatures =   {
      'encoding' => [1, 1, 1],
      'data_encoding' => [1, 1, 1],
      'max_children' => [1, 1, 1],
      'max_data' => [1, 1, 1],
      'max_depth' => [1, 1, 1],
      'multiple_sessions' => [0, 0, 0],
      'language_supports_threads' => [1, 0, 1],
      'language_name' => [1, 0, 1],
      'language_version' => [1, 0, 1],
      'protocol_version' => [1, 0, 1],
      'supports_async' => [1, 1, 1],
      'multiple_sessions' => [0, 0, 0],

        # Internal settings (that should be exposed to the IDE somehow)

        # This one's used for sorting an object's attribute names
        'sort_ignore_at_signs' => [1, 1, 1],

        #XXX Add support for call return exception watch
        'breakpoint_types' => [1, 0, %w/line conditional/],
        'breakpoint_threads' => [1, 0, 0],
        'breakpoint_languages' => [1, 0, %w/Ruby/],
      }

      # Feature name => [value, allowed settable values, if constrained]

      @settings = {
        'encoding' => ['UTF-8', ['UTF-8', 'iso-8859-1']],
        'data_encoding' => ['base64', ['urlescape', 'base64', 'none', 'binary']],
        # binary  and 'none' are the same
        'max_children' => [10, 1],
        'max_data' => [32767, 1],
        'max_depth' => [1, 1],
        'language_name' => ['Ruby'],
        'language_version' => [RUBY_VERSION],
        'protocol_version' => ['1.0'],
        'supports_async' => [1, [0, 1]],
        
        'sort_ignore_at_signs' => [1, [0, 1]],
      }
    end

    def get
      return [@supportedCommands, @supportedFeatures, @settings]
    end

    def clone
      sc = {}
      sf = {}
      settings = {}
      @supportedCommands.each_pair { |k, v| sc[k] = v }
      @supportedFeatures.each_pair { |k, v| sf[k] = v.clone } # Copy ints
      @settings.each_pair { |k, v| settings[k] = [v[0], v[1]] }
      [sc, sf, settings]
    end
  end # end class
end # end module
end # end Debugger module
