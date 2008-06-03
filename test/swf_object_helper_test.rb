require File.join(File.dirname(__FILE__), 'test_helper')

class StubView < ActionView::Base
  include SWFObjectHelper
end

class SWFObjectHelperTest < Test::Unit::TestCase
  def setup
    @view = StubView.new
  end

  def test_swf_object_js_should_wrap_embed_in_javascript_tag
    options = {}
    assert_equal "<script type=\"text/javascript\">\n//<![CDATA[\nswfobject.embedSWF(\"\",\"\",\"\",\"\",\"\",\"\",{},{},{});\n//]]>\n</script>",
      @view.swf_object_js(options)
  end

  def test_string_arguments_from_options_should_encode_arguments_as_json_strings
    options = {}
    (SWFObjectHelper::REQUIRED_ARGUMENTS + SWFObjectHelper::OPTIONAL_ARGUMENTS).each_with_index do |arg, i|
      options[arg] = i
    end

    assert_equal [ '"0"', '"1"', '"2"', '"3"', '"4"', '"5"' ],
      @view.swf_object_string_arguments_from_options(options)
  end

  def test_hash_arguments_from_options_should_encode_hash_arguments_as_json_hashes
    args = []
    SWFObjectHelper::HASH_ARGUMENTS.each_with_index do |arg, i|
      args << arg
      args << { :key => "arg-#{i}" }
    end
    options = Hash[*args]

    assert_equal [ "{\"key\":\"arg-0\"}", "{\"key\":\"arg-1\"}", "{\"key\":\"arg-2\"}" ],
      @view.swf_object_hash_arguments_from_options(options)
  end

  def test_hash_arguments_from_options_should_url_encode_flashvars_values
    options = { :flashvars => { :loader_url => 'http://cdn.host.com/promo.mp3' } }
    args = @view.swf_object_hash_arguments_from_options(options)

    flashvars_json = args.find { |json| json =~ /loader_url/ }

    assert_equal "{\"loader_url\":\"http%3A%2F%2Fcdn.host.com%2Fpromo.mp3\"}",
      flashvars_json
  end

  def test_swf_object_args
    assert_equal "\"\",\"\",\"\",\"\",\"\",\"\",{},{},{}",
      @view.swf_object_args({})
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
    assert_nil @view.add_swf_object_default_attributes!(nil)
  end

  def test_add_default_attributes_should_supply_default_value_if_provided_true
    attributes = Hash[*SWFObjectHelper::OPTIONAL_ATTRIBUTES_WITH_DEFAULT_VALUES.map do |k|
      [ k, true ]
    end.flatten]
    expected_attributes = Hash[*SWFObjectHelper::OPTIONAL_ATTRIBUTES_WITH_DEFAULT_VALUES.map do |k|
      [ k, SWFObjectHelper::OPTIONAL_ATTRIBUTES_POSSIBLE_VALUES[k].first ]
    end.flatten]

    @view.add_swf_object_default_attributes!(attributes)

    assert_equal expected_attributes, attributes
  end

  def test_add_default_attributes_should_raise_on_bad_attribute_format
    attributes = { :bgcolor => 'invalid format' }
    assert_raise ArgumentError do
      @view.add_swf_object_default_attributes!(attributes)
    end
  end

  def test_add_default_attributes_should_not_raise_on_good_attribute_format
    attributes = { :bgcolor => '#ffffff' }
    assert attributes.keys.all? do |key|
      SWFObjectHelper::OPTIONAL_ATTRIBUTES_WITH_REQUIRED_FORMATS.include?(key)
    end
    assert_nothing_raised ArgumentError do
      @view.add_swf_object_default_attributes!(attributes)
    end
  end

  def test_add_default_attributes_should_raise_when_non_string_argument_provided_for_attribute_with_no_default
    attributes = Hash[*SWFObjectHelper::OPTIONAL_ATTRIBUTES_WITH_REQUIRED_VALUES.map do |k|
      [ k, true ]
    end.flatten]
    assert_raise ArgumentError do
      @view.add_swf_object_default_attributes!(attributes)
    end
  end

  def test_add_default_attributes_should_raise_when_disallowed_attribute_provided
    attributes = { :key => 'value' }
    assert attributes.keys.all? do |k|
      SWFObjectHelper::OPTIONAL_ATTRIBUTES.include? k
    end
    assert_raise ArgumentError do
      @view.add_swf_object_default_attributes!(attributes)
    end
  end

  def test_add_default_attributes_should_not_add_unprovided_keys
    attributes = { :base => 'base value' }
    expected_keys = attributes.keys
    unexpected_keys = SWFObjectHelper::OPTIONAL_ATTRIBUTES - attributes.keys
    @view.add_swf_object_default_attributes!(attributes)
    all_expected_keys_found = expected_keys.all? do |key|
      attributes.has_key?(key)
    end
    no_unexpected_keys_found = unexpected_keys.all? do |key|
      !attributes.has_key?(key)
    end

    assert all_expected_keys_found, "Should have provided these keys: #{expected_keys.join(' ')}"
    assert no_unexpected_keys_found, "Should not have provided these keys: #{unexpected_keys.join(' ')}"
  end

end
