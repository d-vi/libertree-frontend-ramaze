# encoding: utf-8

require 'spec_helper'

describe Libertree do
  describe '#render' do
    it 'should escape XHTML tags' do
      subject.render('<script>alert("hello world")</script>').should =~ /<p>alert\(.hello world.\)<\/p>/
    end

    it 'should not strip tags in code blocks' do
      subject.render('`<span>tag soup</span>`').should =~ /&lt;span&gt;tag soup&lt;\/span&gt;/
    end

    it 'should autolink URLs' do
      url = "http://elephly.net"
      subject.render(url).should =~ %r{<a href="#{url}">#{url}</a>}
      subject.render("hello #{url}").should =~ %r{hello <a href="#{url}">#{url}</a>}
      subject.render("This is a link:\n\n#{url}").should =~ %r{<a href="#{url}">#{url}</a>}

      url = "http://elephly.net/index.pl?abc=def&yyz=rush"
      subject.render(url).should =~ Regexp.new(Regexp.escape("<a href=\"#{url.gsub('&','&amp;')}\">#{url.gsub('&','&amp;')}</a>"))

      url = "www.gnu.org"
      subject.render(url).should =~ %r{<a href="#{url}">#{url}</a>}

      # should also work in lists
      subject.render("- #{url}").should =~ %r{<a href="#{url}">#{url}</a>}
    end

    it 'should not mangle underscores in URLs' do
      subject.render('http://this_is_too_cool.com').should =~ %r{this_is_too_cool}
    end

  end
end
