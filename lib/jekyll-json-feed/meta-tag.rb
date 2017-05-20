module JekyllJsonFeed
  class MetaTag < Liquid::Tag
    # Use Jekyll's native relative_url filter
    include Jekyll::Filters::URLFilters

    def render(context)
      @context = context
      attrs    = attributes.map { |k, v| %(#{k}="#{v}") }.join(" ")
      "<link #{attrs} />"
    end

    private

    def config
      @context.registers[:site].config
    end

    def attributes
      {
        :type  => "application/json",
        :rel   => "alternate",
        :href  => absolute_url(path),
        :title => title,
      }.keep_if { |_, v| v }
    end

    def path
      if config["json_feed"] && config["json_feed"]["path"]
        config["json_feed"]["path"]
      else
        "feed.json"
      end
    end

    def title
      config["title"] || config["name"]
    end
  end
end
