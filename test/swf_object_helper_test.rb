require File.join(File.dirname(__FILE__), 'test_helper')

class StubView < ActionView::Base
  include SWFObjectHelper
end

class SWFObjectHelperTest < Test::Unit::TestCase
  def setup
    @view = StubView.new
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

  def test_should_url_encode_flashvars_values
    options = { :flashvars => { :loader_url => 'http://cdn.host.com/promo.mp3' } }
    args = @view.swf_object_hash_arguments_from_options(options)

    flashvars_json = args.find { |json| json =~ /loader_url/ }

    assert_equal "{\"loader_url\":\"http%3A%2F%2Fcdn.host.com%2Fpromo.mp3\"}",
      flashvars_json
  end

  def test_swf_object_args
    assert_equal "\"\", \"\", \"\", \"\", \"\", \"\", {}, {}, {}",
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

      assert_raise ArgumentError do
        @view.ensure_required_options! options
      end
    end
  end

  def test_ensure_required_arguments_should_not_raise
    options = {}
    SWFObjectHelper::REQUIRED_ARGUMENTS.each { |arg| options[arg] = :supplied }
    assert_nothing_raised ArgumentError do
      @view.ensure_required_options! options
    end
  end

end
