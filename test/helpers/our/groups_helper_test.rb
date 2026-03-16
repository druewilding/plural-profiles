require "test_helper"

class Our::GroupsHelperTest < ActionView::TestCase
  FakeTheme = Struct.new(:name, :id)

  test "grouped_theme_options includes Our themes when user themes present" do
    our_themes = [ FakeTheme.new("Dark Forest", 1), FakeTheme.new("Sunset", 2), FakeTheme.new("Ocean Shared", 3) ]
    result = grouped_theme_options(our_themes, [])
    labels = result.map(&:first)
    assert_includes labels, "Our themes"
  end

  test "grouped_theme_options omits Our themes when user themes empty" do
    result = grouped_theme_options([], [])
    labels = result.map(&:first)
    assert_not_includes labels, "Our themes"
  end

  test "grouped_theme_options includes Shared themes when shared themes present" do
    shared = [ FakeTheme.new("Ocean Shared", 10) ]
    result = grouped_theme_options([], shared)
    labels = result.map(&:first)
    assert_includes labels, "Shared themes"
  end

  test "grouped_theme_options omits Shared themes when shared themes empty" do
    result = grouped_theme_options([], [])
    labels = result.map(&:first)
    assert_not_includes labels, "Shared themes"
  end

  test "grouped_theme_options maps personal themes to [name, id] pairs" do
    personal = [ FakeTheme.new("Dark Forest", 1) ]
    result = grouped_theme_options(personal, [])
    options = result.find { |label, _| label == "Our themes" }.last
    assert_equal [ [ "Dark Forest", 1 ] ], options
  end

  test "grouped_theme_options returns empty array when both collections empty" do
    assert_equal [], grouped_theme_options([], [])
  end
end
