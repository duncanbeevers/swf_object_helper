require File.join(File.dirname(__FILE__), 'test_helper')

class StubView < ActionView::Base
  include SWFObjectHelper
end

PARAMS_SET_TO_DEFAULT_VALUES = Hash[*SWFObjectHelper::PARAMS_WITH_DEFAULT_VALUES.map do |k|
  [ k, SWFObjectHelper::PARAMS_POSSIBLE_VALUES[k].first ]
end.flatten]

class SWFObjectHelperTest < Test::Unit::TestCase
  def setup
    @view = StubView.new
  end
  
  def test_swf_object_js_should_not_wrap_embed_in_javascript_tag
    options = { :url => 'url', :id => 'id', :width => 100, :height => 100, :version => 1 }
    assert_equal "swfobject.embedSWF(\"url\",\"id\",\"100\",\"100\",\"1\",null,{},{},{});",
      @view.swf_object_js(options)
  end

  def test_string_arguments_from_options_should_encode_arguments_as_json_strings
    options = {}
    (SWFObjectHelper::REQUIRED_ARGUMENTS + SWFObjectHelper::OPTIONAL_ARGUMENTS).each_with_index do |arg, i|
      options[arg] = i
    end
    
    assert_equal [ '"0"', '"1"', '"2"', '"3"', '"4"', '"5"' ],
      @view.swf_object_encoded_args(options)[0..(options.size - 1)]
  end
  
  def test_hash_arguments_from_options_should_url_encode_flashvars_values
    options = { :flashvars => { :loader_url => 'http://cdn.host.com/promo.mp3' } }
    args = @view.swf_object_hash_arguments_from_options(options)
    loader_url = args.first[:loader_url]
    
    assert_equal "http%3A%2F%2Fcdn.host.com%2Fpromo.mp3",
      loader_url
  end
  
  def test_swf_object_args
    assert_equal [ "url", "id", "100", "200", "1", nil, {}, {}, {} ],
      @view.swf_object_args({ :url => 'url', :id => 'id', :width => 100, :height => 200, :version => 1 })
  end
  
  def test_apply_option_transformations_should_parse_size
    options = { :size => '100x200' }
    @view.apply_swf_object_option_transformations! options
    assert_equal '100', options[:width], 'Should have parsed width from size'
    assert_equal '200', options[:height], 'should have parsed height from size'
  end
  
  def test_apply_option_transformations_should_fill_in_alt_text
    options = { :alt => true, :version => 'version_number' }
    @view.apply_swf_object_option_transformations! options
    assert_equal "This website requires <a href=\"http://www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash\">Flash player</a> version_number or higher.",
      options[:alt]
  end
  
  def test_ensure_required_arguments_should_raise_on_missing_requirement
    SWFObjectHelper::REQUIRED_ARGUMENTS.each do |arg|
      options = {}
      most_required_arguments = SWFObjectHelper::REQUIRED_ARGUMENTS - [ arg ]
      most_required_arguments.each { |supplied_arg| options[supplied_arg] = :supplied }
      
      assert_raise ArgumentError, "Should raise error when not supplied with required argument #{arg}" do
        @view.ensure_swf_object_required_options! options
      end
    end
  end
  
  def test_ensure_required_arguments_should_not_raise
    options = {}
    SWFObjectHelper::REQUIRED_ARGUMENTS.each { |arg| options[arg] = :supplied }
    assert_nothing_raised ArgumentError do
      @view.ensure_swf_object_required_options! options
    end
  end
  
  def test_add_default_attributes_should_not_modify_nil
    assert_nil @view.add_swf_object_default_params!(nil)
  end
  
  def test_add_default_params_should_supply_default_value_if_provided_true
    attributes = Hash[*SWFObjectHelper::PARAMS_WITH_DEFAULT_VALUES.map do |k|
      [ k, true ]
    end.flatten]
    
    @view.add_swf_object_default_params!(attributes)
    
    assert_equal PARAMS_SET_TO_DEFAULT_VALUES, attributes
  end
  
  def test_add_default_attributes_should_raise_on_bad_attribute_format
    attributes = { :bg_color => 'invalid format' }
    assert_raise ArgumentError do
      @view.add_swf_object_default_params!(attributes)
    end
  end
  
  def test_add_default_attributes_should_not_raise_on_good_attribute_format
    attributes = { :bg_color => '#ffffff' }
    attributes_require_format = attributes.keys.all? do |key|
      SWFObjectHelper::PARAMS_WITH_REQUIRED_FORMATS.include?(key)
    end
    assert attributes_require_format
    assert_nothing_raised ArgumentError do
      @view.add_swf_object_default_params!(attributes)
    end
  end
  
  def test_add_default_attributes_should_raise_when_non_string_argument_provided_for_attribute_with_no_default
    attributes = Hash[*SWFObjectHelper::PARAMS_WITH_REQUIRED_VALUES.map do |k|
      [ k, true ]
    end.flatten]
    assert_raise ArgumentError do
      @view.add_swf_object_default_params!(attributes)
    end
  end
  
  def test_add_default_attributes_should_raise_when_disallowed_attribute_provided
    attributes = { :key => 'value' }
    invalid_attribute_provided = attributes.keys.any? do |k|
      !SWFObjectHelper::PARAMS.include? k
    end
    assert invalid_attribute_provided
    assert_raise ArgumentError do
      @view.add_swf_object_default_params!(attributes)
    end
  end
  
  def test_add_default_attributes_should_not_add_unprovided_keys
    attributes = { :base => 'base value' }
    expected_keys = attributes.keys
    unexpected_keys = SWFObjectHelper::PARAMS - attributes.keys
    @view.add_swf_object_default_params!(attributes)
    all_expected_keys_found = expected_keys.all? do |key|
      attributes.has_key?(key)
    end
    no_unexpected_keys_found = unexpected_keys.all? do |key|
      !attributes.has_key?(key)
    end
    
    assert all_expected_keys_found, "Should have provided these keys: #{expected_keys.join(', ')}"
    assert no_unexpected_keys_found, "Should not have provided these keys: #{unexpected_keys.join(', ')}"
  end
  
  def test_coercion_for_allow_links
    params = { :allow_links => true }
    @view.add_swf_object_default_params!(params)
    assert_equal 'all', params[:allow_links], 'Expected a true value for allow_links to cast to all'
    
    params = { :allow_links => 'all' }
    @view.add_swf_object_default_params!(params)
    assert_equal 'all', params[:allow_links], 'Expected explicit all value for allow_links to remain all'
    
    params = { :allow_links => false }
    @view.add_swf_object_default_params!(params)
    assert_equal 'internal', params[:allow_links], 'Expected a false value for allow_links to cast to internal'
    
    params = { :allow_links => 'internal' }
    @view.add_swf_object_default_params!(params)
    assert_equal 'internal', params[:allow_links], 'Expected explicit internal value for allow_links to remain internal'
  end
  
  def test_coercion_for_allow_script_access
    params = { :allow_script_access => true }
    @view.add_swf_object_default_params!(params)
    assert_equal 'sameDomain', params[:allow_script_access], 'Expected a true value for allow_script_access to cast to sameDomain'
    
    params = { :allow_script_access => 'sameDomain' }
    @view.add_swf_object_default_params!(params)
    assert_equal 'sameDomain', params[:allow_script_access], 'Expected explicit sameDomain value for allow_script_access to remain sameDomain'
    
    params = { :allow_script_access => false }
    @view.add_swf_object_default_params!(params)
    assert_equal 'never', params[:allow_script_access], 'Expected a false value for allow_script_access to cast to never'
    
    params = { :allow_script_access => 'never' }
    @view.add_swf_object_default_params!(params)
    assert_equal 'never', params[:allow_script_access], 'Expected explicit never value for allow_script_access to remain never'
    
    params = { :allow_script_access => 'always' }
    @view.add_swf_object_default_params!(params)
    assert_equal 'always', params[:allow_script_access], 'Expected explicit always value for allow_script_access to remain always'
  end
  
  def test_emitted_attribute_names_should_remove_underscore
    options = { :url => 'url', :id => 'id', :width => 100, :height => 200, :version => 1,
      :params => PARAMS_SET_TO_DEFAULT_VALUES }
    params = JSON.parse(@view.swf_object_encoded_args(options)[-2])
    
    PARAMS_SET_TO_DEFAULT_VALUES.each do |param, v|
      encoded_param = param.to_s.gsub('_', '')
      assert params.has_key?(encoded_param), "Expected params to have encoded #{param} as #{encoded_param}"
    end
  end
  
  def test_should_not_json_encode_js_params
    options = { :url => 'url', :id => 'id', :width => 100, :height => 100, :version => 1,
      :flashvars => { :channel_id => SWFObjectHelper::JSParam.new('channel_id') } }
    flashvars = @view.swf_object_encoded_args(options)[-3]
    assert_equal "{\"channel_id\":channel_id}", flashvars
  end
  
end
