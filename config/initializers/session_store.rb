# The framework session (used for e.g. return_to_after_authenticating in
# Authentication) needs to survive the hop between the chat. subdomain and
# the main domain during sign-in — same reason the custom session_id cookie
# in Authentication#start_new_session_for is scoped with domain: :all.
#
# tld_length: 2 is required here, not just a nicety — domain: :all's default
# heuristic (no tld_length given) misdetects two-part dev/test hosts like
# lvh.me as a compound TLD (the same shape as .co.uk), computing the cookie
# domain as the full "chat.lvh.me" instead of stripping down to "lvh.me".
# That silently breaks flash messages (a fresh, differently-scoped cookie
# gets set on every chat.* response, fighting the one from the apex domain).
Rails.application.config.session_store :cookie_store, key: "_plural_profiles_session", domain: :all, tld_length: 2
