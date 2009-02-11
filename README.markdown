SWFObjectHelper
=

Embed swfs
-
Embed swfs with a friendly, keyed syntax.

    <%= swf_object(
      :url => '/flash/turbolift.swf',
      :id => 'game_swf',
      :width => '100',
      :height => '200',
      :version => '9',
      :params => {
        :bg_color => '#ffffff',
        :allow_script_access => false
      },
      :flashvars => {
        :api_version => 1,
        :debug_level => 2,
        :local_connection_channel_id => SWFObjectHelper::JSParam.new('(new Date().getTime())')
      }
    ) %>

Ensure valid usage of object params
-
Values passed via <tt>:params</tt> are validated against the [allowed values prescribed by Adobe](http://www.adobe.com/cfusion/knowledgebase/index.cfm?id=tn_12701).

Pass flashvars
-
Values passed via <tt>:flashvars</tt> are automatically url-encoded, allowing you to thread data through to your swf without write a lot of string-munging code.

Compatible with swfobject 2.1
-
Generates JavaScript and optionally alternative content for [SWFObject v2.1](http://code.google.com/p/swfobject/wiki/documentation)

Some Details
-
Required attributes for swf_object are:

*  url &mdash; The url of the swf to be embedded
*  id &mdash; The id of the dom node which the swf will replace
*  width &mdash; The width in pixels of the swf to be embedded
*  height &mdash; The height in pixels of the swf to be embedded
*  version &mdash; The minimum flash version necessary to display the provided content

All params values prescribed by Adobe are supported.
See the [Adobe Documentation](http://www.adobe.com/cfusion/knowledgebase/index.cfm?id=tn_12701) or <tt>SWFObjectHelper::PARAMS\_POSSIBLE_VALUES</tt> for possible values.

SWFObject::JSParam
-
If you need to supply javascript as parameter to SWFObject, you can avoid the
JSON escaping using the JSParam object.  For example, say you have specified a timestamp
to be passed along with the flashvars, your embed call may look something
like this:

    var channel_id = new Date().getTime();
    <%= swf_object(
      :url => 'http://example.com/demo.swf',
      :id => 'dom_id', :width => 100, :height => 100, :version => 9,
      :flashvars => {
        :channel_id => SWFObjectHelper::JSParam.new('(new Date().getTime())')
      }
    ) %>

Alternative Content
-
Calling swf_object automatically creates an empty containing div for the generated
swf.

    <%= swf_object(...) %>

Provide a block to provide alternate content for when the flash player is not
available:

    <% swf_object(...) do %>
      <p>Get Flash, fool!</p>
    <% end %>

Like other helpers that take blocks, this will concatenate the generated code to
the ERB output stream directly, so use <tt><% %> </tt> instead of <tt><%= %></tt> if a block is given.

Or, pass <tt>:alt => true</tt> to generate string output including default alternative content:

    <%= swf_object(..., :id => 'alt_content', :alt => true) %>
    # => <div id='alt_content'>This website requires ...</div><script ...

or pass <tt>:alt => "some string"</tt> to manually specify the alternative content:

    <%= swf_object(..., :id => 'alt_content', :alt => "no flash") %>
    # => <div id='alt_content'>no flash</div><script ...

If you already have a containing element in your markup, you can generate just the
javascript necessary to embed the swf by using <tt>swf\_object\_js</tt>.
Note that if you use this method, you will need to wrap the js in a <tt>&lt;script></tt> block

    <%= javascript_tag(swf_object_js(...)) %>

Credits
-
Originally by Henrik N - [http://henrik.nyh.se/]()

Updated by Duncan Beevers - [http://www.dweebd.com]()
