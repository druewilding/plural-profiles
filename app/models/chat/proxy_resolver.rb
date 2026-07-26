module Chat
  # Tupperbox-style proxying: given a user and a raw chat message body, finds
  # whichever of the user's own profiles or groups has a
  # chat_bracket_before/chat_bracket_after template matching the body — e.g.
  # before "guy:" matches a body starting with "guy:" exactly (case-
  # SENSITIVELY — "Guy:"/"GUY:" won't match "guy:"; different cases of the
  # same letters are deliberately allowed to identify different postables),
  # before "{" / after "}" matches a body wrapped in braces. When more than
  # one postable matches, the one with the longer (more specific) brackets
  # wins. Returns nil, or a hash with the matched postable and the message
  # content with the brackets stripped off.
  #
  # Generalizes the profile-only Profile.resolve_chat_proxy that used to live
  # on Chat::Message's counterpart — see ChatProxyable for the per-model half
  # (normalization + uniqueness) this depends on.
  module ProxyResolver
    def self.resolve(user, body)
      return if body.blank?

      candidates = [ user.profiles, user.groups ].flat_map do |scope|
        scope.where("chat_bracket_before IS NOT NULL OR chat_bracket_after IS NOT NULL").to_a
      end

      candidates.filter_map { |postable|
        prefix = postable.chat_bracket_before.to_s
        suffix = postable.chat_bracket_after.to_s
        next unless body.length >= prefix.length + suffix.length
        next unless body[0, prefix.length] == prefix
        next unless suffix.blank? || body[-suffix.length, suffix.length].to_s == suffix
        content_end = suffix.blank? ? body.length : body.length - suffix.length
        content = body[prefix.length...content_end].to_s.strip
        next if content.blank?
        { postable: postable, content: content, specificity: prefix.length + suffix.length }
      }.max_by { |match| match[:specificity] }
    end
  end
end
