module ApplicationHelper
  DESCRIPTION_EXTRA_TAGS = %w[details summary span b i u s table thead tbody tfoot tr th td].to_set.freeze
  DESCRIPTION_EXTRA_ATTRIBUTES = %w[open class role tabindex aria-label aria-expanded colspan rowspan].to_set.freeze

  SPOILER_PATTERN = /\|\|(.+?)\|\|/m
  CODE_BLOCK_PATTERN = /<code(?:\s[^>]*)?>.*?<\/code>/m

  SPOILER_REPLACEMENT = '<span class="spoiler" role="button" tabindex="0" ' \
    'aria-expanded="false" aria-label="Hidden content, click to reveal">\1</span>'

  HEART_EMOJI_PATTERN = /:([a-z0-9_]+_heart):/i

  # Newlines adjacent to these block-level tags get stripped before simple_format
  # runs, to prevent them being turned into <br> or <p> inside structured HTML.
  # Limited to table structural tags — other block elements (div, details, etc.)
  # can appear in flow text where blank lines ARE meaningful paragraph breaks.
  BLOCK_TAG_NAMES = "table|thead|tbody|tfoot|tr|th|td"
  BLOCK_TAG_TRAILING_NEWLINE_RE = Regexp.new(
    "(</?(?:#{BLOCK_TAG_NAMES})(?:\\s[^>]*)?>)\\s*\\n+\\s*",
    Regexp::IGNORECASE
  ).freeze
  BLOCK_TAG_LEADING_NEWLINE_RE = Regexp.new(
    "\\s*\\n+\\s*(?=</?(?:#{BLOCK_TAG_NAMES})\\b)",
    Regexp::IGNORECASE
  ).freeze

  def formatted_description(text)
    safe_list_class = self.class.safe_list_sanitizer.class
    tags = safe_list_class.allowed_tags + DESCRIPTION_EXTRA_TAGS
    attrs = safe_list_class.allowed_attributes + DESCRIPTION_EXTRA_ATTRIBUTES
    text = convert_spoilers_outside_code(text)
    text = strip_block_tag_newlines(text)
    html = simple_format(text, {}, sanitize_options: { tags: tags, attributes: attrs })
    html = html.gsub("</details>", '<button type="button" class="details-close" aria-label="Close details">(click to close)</button></details>')
    html = replace_heart_emojis(html)
    html.html_safe
  end

  def relative_time(time)
    return "unknown" unless time
    if time.future?
      "#{distance_of_time_in_words(Time.current, time)} from now"
    else
      "#{time_ago_in_words(time)} ago"
    end
  end

  def avatar_shape_class(record, prefix: "avatar")
    case record.avatar_shape
    when "circle" then "#{prefix}--circle"
    when "square" then "#{prefix}--square"
    else ""
    end
  end

  private

  def strip_block_tag_newlines(text)
    text.gsub(BLOCK_TAG_TRAILING_NEWLINE_RE, '\1')
        .gsub(BLOCK_TAG_LEADING_NEWLINE_RE, "")
  end

  def replace_heart_emojis(html)
    # Only replace hearts in text nodes — skip <code>...</code> blocks and HTML tags
    # so that heart codes inside attributes (e.g. title=":11_aqua_heart:") are preserved
    skip_pattern = /#{CODE_BLOCK_PATTERN}|<[^>]*>/m
    parts = html.split(skip_pattern)
    non_text = html.scan(skip_pattern)

    result = parts.map do |part|
      part.gsub(HEART_EMOJI_PATTERN) do |match|
        name = Regexp.last_match(1).downcase
        canonical = Profile.resolve_heart_emoji(name)
        if canonical
          display = Profile.heart_emoji_display_name(canonical)
          '<img src="/images/hearts/%s.webp" title="%s" alt="%s" class="heart-inline" width="24" height="24" loading="lazy">' % [ canonical, display, display ]
        else
          match
        end
      end
    end
    non_text.each_with_index { |segment, i| result.insert((i * 2) + 1, segment) }
    result.join
  end

  def convert_spoilers_outside_code(text)
    # Split on <code>...</code> blocks so we only convert ||text|| outside them
    parts = text.split(CODE_BLOCK_PATTERN)
    code_blocks = text.scan(CODE_BLOCK_PATTERN)

    result = parts.map { |part| part.gsub(SPOILER_PATTERN, SPOILER_REPLACEMENT) }
    code_blocks.each_with_index { |block, i| result.insert((i * 2) + 1, block) }
    result.join
  end
end
