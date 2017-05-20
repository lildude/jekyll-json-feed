require 'spec_helper'

describe(JekyllJsonFeed) do
  let(:overrides) { Hash.new }
  let(:config) do
    Jekyll.configuration(Jekyll::Utils.deep_merge_hashes({
      "full_rebuild" => true,
      "source"      => source_dir,
      "destination" => dest_dir,
      "show_drafts" => true,
      "url"         => "http://example.org",
      "name"        => "My awesome site",
      "author"      => {
        "name"      => "Dr. Jekyll",
        "url"       => "http://example.org/dr_jekyll",
        "avatar"    => "http://example.org/dr_jekyll/avatar.png"
      },
      "collections" => {
        "my_collection" => { "output" => true },
        "other_things"  => { "output" => false }
      }
    }, overrides))
  end
  let(:site)     { Jekyll::Site.new(config) }
  let(:contents) { File.read(dest_dir("feed.json")) }
  let(:context)  { make_context(site: site) }
  let(:json_feed_meta) { Liquid::Template.parse("{% json_feed_meta %}").render!(context, {}) }
  before(:each) do
    site.process
  end

  it "has no layout" do
    expect(contents).not_to match(/\ATHIS IS MY LAYOUT/)
  end

  it "creates a feed.json file" do
    expect(Pathname.new(dest_dir("feed.json"))).to exist
  end


  it "doesn't have multiple new lines or trailing whitespace" do
    expect(contents).to_not match /\s+\n/
    expect(contents).to_not match /\n{2,}/
  end

  it "puts all the posts in the feed.json file" do
    expect(contents).to match /http:\/\/example\.org\/2014\/03\/04\/march-the-fourth\.html/
    expect(contents).to match /http:\/\/example\.org\/2014\/03\/02\/march-the-second\.html/
    expect(contents).to match /http:\/\/example\.org\/2013\/12\/12\/dec-the-second\.html/
    expect(contents).to match "http://example.org/2015/08/08/stuck-in-the-middle.html"
    expect(contents).to_not match /http:\/\/example\.org\/2016\/02\/09\/a-draft\.html/
  end

  it "does not include assets or any static files that aren't .html" do
    expect(contents).not_to match /http:\/\/example\.org\/images\/hubot\.png/
    expect(contents).not_to match /http:\/\/example\.org\/feeds\/atom\.xml/
  end

  it "preserves linebreaks in preformatted text in posts" do
    expect(contents).to match /Line 1\\nLine 2\\nLine 3/
  end

  it "supports post author name as an object" do
    expect(contents).to match %r!"author":\s*{\s*"name":\s*"Ben",\s*"url":\s*"http://ben.balter.com"\s*}!
  end

  it "supports post author name as a string" do
    expect(contents).to match %r!"author":\s*{\s*"name":\s*"Pat"\s*}!
  end

  it "does not output author tag no author is provided" do
    expect(contents).not_to match %r{"author":\s*{\s*}}
  end

  it "does use author reference with data from _data/authors.yml" do
    expect(contents).to match %r!"author":\s*{\s*"name": "Garth",\s*"url":\s*"http://garthdb.com"\s*}!
  end

  it "converts markdown posts to HTML" do
    expect(contents).to match %r{<p>March the second!</p>}
  end

  it "uses last_modified_at where available" do
    expect(contents).to match %r{"date_modified": "2015-05-12T13:27:59\+00:00"}
  end

  it "replaces newlines in posts to spaces" do
    expect(contents).to match %r!"title": "The plugin will properly strip newlines."!
  end

  it "renders Liquid inside posts" do
    expect(contents).to match /Liquid is rendered\./
    expect(contents).not_to match /Liquid is not rendered\./
  end

  it "includes the item image" do
    expect(contents).to include('"image": "http://example.org/image.png"')
    expect(contents).to include('"image": "https://cdn.example.org/absolute.png"')
    expect(contents).to include('"image": "http://example.org/object-image.png"')
  end

  context "parsing" do
    let(:feed) { JSON.parse(contents) }

    it "outputs a JSON feed" do
      expect(feed['version']).to eql("https://jsonfeed.org/version/1")
    end

    it "outputs the link" do
      expect(feed['feed_url']).to eql("http://example.org/feed.json")
    end

    it "includes the items" do
      expect(feed['items'].count).to eql(10)
    end

    it "includes item contents" do
      post = feed['items'].last
      expect(post['title']).to eql("Dec The Second")
      expect(post['url']).to eql("http://example.org/2013/12/12/dec-the-second.html")
      expect(post['date_published']).to eql(Time.parse("2013-12-12").iso8601)
    end

    it "includes the item's excerpt" do
      post = feed['items'].last
      expect(post['summary']).to eql("Foo")
    end

    it "doesn't include the item's excerpt if blank" do
      post = feed['items'].first
      expect(post['summary']).to be_nil
    end

    context "with site.title set" do
      let(:site_title) { "My Site Title" }
      let(:overrides) { {"title" => site_title} }

      it "uses site.title for the title" do
        expect(feed['title']).to eql(site_title)
      end
    end

    context "with site.name set" do
      let(:site_name) { "My Site Name" }
      let(:overrides) { {"name" => site_name} }

      it "uses site.name for the title" do
        expect(feed['title']).to eql(site_name)
      end
    end

    context "with site.name and site.title set" do
      let(:site_title) { "My Site Title" }
      let(:site_name) { "My Site Name" }
      let(:overrides) { {"title" => site_title, "name" => site_name} }

      it "uses site.title for the title, dropping site.name" do
        expect(feed['title']).to eql(site_title)
      end
    end
  end

  context "smartify" do
    let(:site_title) { "Pat's Site" }
    let(:overrides) { { "title" => site_title } }
    let(:feed) { JSON.parse(contents) }

    it "processes site title with SmartyPants" do
      expect(feed['title']).to eql("Pat’s Site")
    end
  end

  context "with a baseurl" do
    let(:overrides) do
      { "baseurl" => "/bass" }
    end

    it "correctly adds the baseurl to the posts" do
      expect(contents).to match /http:\/\/example\.org\/bass\/2014\/03\/04\/march-the-fourth\.html/
      expect(contents).to match /http:\/\/example\.org\/bass\/2014\/03\/02\/march-the-second\.html/
      expect(contents).to match /http:\/\/example\.org\/bass\/2013\/12\/12\/dec-the-second\.html/
    end

    it "renders the feed meta" do
      expected = 'href="http://example.org/bass/feed.json"'
      expect(json_feed_meta).to include(expected)
    end
  end

  context "feed meta" do
    it "renders the feed meta" do
      expected = '<link type="application/json" rel="alternate" href="http://example.org/feed.json" title="My awesome site" />'
      expect(json_feed_meta).to eql(expected)
    end

    context "with a blank site name" do
      let(:config) do
        Jekyll.configuration({
          "source"      => source_dir,
          "destination" => dest_dir,
          "url"         => "http://example.org"
        })
      end

      it "does not output blank title" do
        expect(json_feed_meta).not_to include('title=')
      end
    end
  end

  context "changing the feed path" do
    let(:overrides) do
      {
        "json_feed" => {
          "path" => "atom.json"
        }
      }
    end

    it "should write to atom.json" do
      expect(Pathname.new(dest_dir("atom.json"))).to exist
    end

    it "renders the feed meta with custom feed path" do
      expected = 'href="http://example.org/atom.json"'
      expect(json_feed_meta).to include(expected)
    end
  end

end
