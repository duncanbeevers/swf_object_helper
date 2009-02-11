# Generates JavaScript and optionally alternative content for SWFObject v2.0:
# http://code.google.com/p/swfobject/wiki/documentation
#
# Pass a block with alternative content to also create a div containing it:
#
#   <% swf_object(...) do %>
#     <p>Get Flash, fool!</p>
#   <% end %>
#
# Like other helpers that take blocks, this will concatenate the generated code to
# the ERB output stream directly, so use <% %> instead of <%= %> if a block is given.
#
# Or, pass :alt => true to generate string output including default alternative content:
#
#   <%= swf_object(..., :id => 'alt_content', :alt => true) %>
#   # => <div id='alt_content'>This website requires ...</div><script ...
#
# or pass :alt => "some string" to put that in the alternative content:
#   <%= swf_object(..., :id => 'alt_content', :alt => "no flash") %>
#   # => <div id='alt_content'>no flash</div><script ...
#
# By default, or if you explicitly pass :alt => false, you will have to create the
# alternative content element yourself.
#
# Originally by Henrik N - http://henrik.nyh.se/ http://pastie.textmate.org/private/nu0hpwxmtcx0toi58j4kha
module SWFObjectHelper
  REQUIRED_ARGUMENTS = [ :url, :id, :width, :height, :version ]
  OPTIONAL_ARGUMENTS = [ :express_install_url ]
  HASH_ARGUMENTS     = [ :flashvars, :params, :attributes ]

  # Optional attributes specified http://kb.adobe.com/selfservice/viewContent.do?externalId=tn_12701
  # First value in possible values array is default
  PARAMS_POSSIBLE_VALUES = {
    :play                => [ 'true', 'false' ],
    :loop                => [ 'true', 'false' ],
    :menu                => [ 'true', 'false' ],
    :quality             => [ 'autohigh', 'low', 'autolow', 'medium', 'high', 'best' ],
    :scale               => [ 'default', 'noorder', 'exactfit' ],
    :salign              => [ 'tl', 'tr', 'bl', 'br', 'l', 'r', 't', 'b' ],
    :wmode               => [ 'window', 'opaque', 'transparent' ],
    :bg_color             => /#[0-9a-fA-F]{6,6}/, # Must match #RRGGBB hexadecimal color
    :sw_live_connect     => [ 'false', 'true' ],
    :device_font         => [ 'true', 'false' ],
    :seamless_tabbing    => [ 'true', 'false' ],
    :allow_fullscreen    => [ 'true', 'false' ],
    :allow_links         => [ 'all', 'internal' ],
    :allow_script_access => [ 'sameDomain', 'always', 'never' ],
    :flashvars           => nil,
    :base                => nil
  }

  def swf_object options = {}, &block
    js = javascript_tag(swf_object_js(options))
    
    if block_given?
      content = capture(&block)
      content = content_tag(:div, content, :id => options[:id])
      concat(content, block.binding)
      concat(js, block.binding)
    elsif options[:alt]
      [ content_tag(:div, options[:alt], :id => options[:id]), js ].join
    else
      [ content_tag(:div, '', :id => options[:id]), js ].join
    end
  end

  def apply_swf_object_option_transformations! options
    options[:width], options[:height] = options[:size].split('x') if options[:size]
    
    if true == options[:alt]
      options[:alt] = %{This website requires #{link_to('Flash player', 'http://www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash')} #{options[:version]} or higher.}
    end
  end
  
  def add_swf_object_default_params! params
    return unless params
    unexpected_params = params.keys - PARAMS
    raise ArgumentError, "Disallowed params provided: #{unexpected_params.join(', ')}" unless unexpected_params.empty?
    
    # params[:allow_links] = 'internal' if false == params[:allow_links]
    # params[:allow_script_access] = 'never' if false == params[:allow_script_access]
    
    params.each do |param, value|
      constraint = PARAMS_POSSIBLE_VALUES[param]
      case constraint
        when Array
          if true == value
            params[param] = constraint.first
          elsif false == value
            params[param] = constraint.last
          else
            raise ArgumentError,
              "Value #{value} for #{param} is not included in #{constraint.join(', ')}" unless constraint.include?(value)
          end
        when Regexp
          raise ArgumentError,
            "Value #{value} for #{param} does not match format #{constraint.inspect}" unless constraint =~ value
        when NilClass
          raise ArgumentError,
            "Value #{value}:#{value.class} for #{param} is invalid, must be a String" unless value.kind_of?(String)
      end
    end
  end
  
  # Generates just the javascript necessary to create a swfobject embed
  def swf_object_js options
    "swfobject.embedSWF(#{swf_object_encoded_args(options).join(',')});"
  end
  
  def swf_object_encoded_args options
    object_args = swf_object_args(options)
    params = object_args[-2]
    object_args[-2] = Hash[*params.map { |a, v| [ a.to_s.gsub('_', ''), v ] }.flatten]
    object_args.map(&:to_json)
  end
  
  def swf_object_args options
    apply_swf_object_option_transformations!(options)
    ensure_swf_object_required_options!(options)
    add_swf_object_default_params!(options[:params])
    
    swf_object_string_arguments_from_options(options) +
    swf_object_hash_arguments_from_options(options)
  end
  
  def swf_object_string_arguments_from_options options
    (REQUIRED_ARGUMENTS + OPTIONAL_ARGUMENTS).map do |arg|
      options[arg] ? options[arg].to_s : nil
    end
  end
  
  def swf_object_hash_arguments_from_options options
    HASH_ARGUMENTS.map do |arg|
      hash = options[arg] || {}
      if :flashvars == arg  # swfobject expects you to url encode flashvars values
        hash = Hash[*hash.inject([]) {|m,(k,v)| m << k << swf_object_url_encode(v) }]
      end
      hash
    end
  end
  
  def swf_object_url_encode v
    case v
      when JSParam then v
      else url_encode(v)
    end
  end
  
  def ensure_swf_object_required_options! options
    missing_arguments = REQUIRED_ARGUMENTS - options.keys
    unless missing_arguments.empty?
      raise ArgumentError, "Missing required SWFObject arguments: #{missing_arguments.join(', ')}"
    end
  end
  
  class JSParam
    def initialize text
      @text = text
    end
    
    def to_json
      @text
    end
  end
  
  # These are for tests
  PARAMS = PARAMS_POSSIBLE_VALUES.keys
  PARAMS_WITH_DEFAULT_VALUES = PARAMS_POSSIBLE_VALUES.map do |k, v|
    v.kind_of?(Array) ? k : nil
  end.compact
  PARAMS_WITH_REQUIRED_FORMATS = PARAMS_POSSIBLE_VALUES.map do |k, v|
    v.kind_of?(Regexp) ? k : nil
  end.compact
  PARAMS_WITH_REQUIRED_VALUES = PARAMS_POSSIBLE_VALUES.map do |k, v|
    nil == v ? k : nil
  end.compact

end
