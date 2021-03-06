# encoding: utf-8

require 'spec_helper'

describe Libertree do
  describe '#hashtaggify' do
    it 'should linkify hashtags' do
      subject.hashtaggify('#simple').should == '<a href="/rivers/ensure_exists/%23simple" class="hashtag">#simple</a>'
      subject.hashtaggify('#99bottles').should == '<a href="/rivers/ensure_exists/%2399bottles" class="hashtag">#99bottles</a>'
      subject.hashtaggify('#number1').should == '<a href="/rivers/ensure_exists/%23number1" class="hashtag">#number1</a>'
      subject.hashtaggify('#hash-tag').should == '<a href="/rivers/ensure_exists/%23hash-tag" class="hashtag">#hash-tag</a>'
      subject.hashtaggify('#hash_tag').should == '<a href="/rivers/ensure_exists/%23hash_tag" class="hashtag">#hash_tag</a>'
      subject.hashtaggify('surrounding #simple words').should == 'surrounding <a href="/rivers/ensure_exists/%23simple" class="hashtag">#simple</a> words'
      subject.hashtaggify('surrounding #simple').should == 'surrounding <a href="/rivers/ensure_exists/%23simple" class="hashtag">#simple</a>'
      subject.hashtaggify('#simple words').should == '<a href="/rivers/ensure_exists/%23simple" class="hashtag">#simple</a> words'
      subject.hashtaggify('#multiple foo #hashtags bar').should == '<a href="/rivers/ensure_exists/%23multiple" class="hashtag">#multiple</a> foo <a href="/rivers/ensure_exists/%23hashtags" class="hashtag">#hashtags</a> bar'
      subject.hashtaggify('#multiple #hashtags').should == '<a href="/rivers/ensure_exists/%23multiple" class="hashtag">#multiple</a> <a href="/rivers/ensure_exists/%23hashtags" class="hashtag">#hashtags</a>'
    end

    it 'should linkify unicode hashtags' do
      subject.hashtaggify('#中国').should == '<a href="/rivers/ensure_exists/%23中国" class="hashtag">#中国</a>'
    end

    it 'should not linkify apparent hashtags with invalid characters' do
      subject.hashtaggify('#<3').should == '#<3'
      subject.hashtaggify('#ab|c').should == '<a href="/rivers/ensure_exists/%23ab" class="hashtag">#ab</a>|c'
    end

    it 'should not linkify hashtag edge cases' do
      subject.hashtaggify(nil).should == ''
      subject.hashtaggify('').should == ''
    end

    it 'should treat hashtags as case-insensitive' do
      subject.hashtaggify('#FooBar').should == '<a href="/rivers/ensure_exists/%23foobar" class="hashtag">#FooBar</a>'
    end
  end

  describe '#render' do
    it 'should linkify hashtags' do
      subject.render('#simple').should == Nokogiri::HTML::fragment(%{<p><a href="/rivers/ensure_exists/%23simple" class="hashtag">#simple</a></p>\n}).to_xhtml
    end

    it 'should linkify hashtags in headings' do
      subject.render('# A #simple heading').should == Nokogiri::HTML::fragment(%{<h1>A <a href="/rivers/ensure_exists/%23simple" class="hashtag">#simple</a> heading</h1>\n}).to_xhtml
    end

    it 'should not linkify hashtags in code blocks' do
      subject.render('`#simple`').should == Nokogiri::HTML::fragment(%{<p><code>#simple</code></p>}).to_xhtml
    end

    it 'should linkify hashtags up to, but excluding, invalid characters.' do
      subject.render('#ab_c').should == Nokogiri::HTML::fragment(%{<p><a href="/rivers/ensure_exists/%23ab" class="hashtag">#ab</a>_c</p>\n}).to_xhtml
    end

    it 'should not linkify hashtag edge cases' do
      subject.render(nil).should == ''
      subject.render('').should == ''
    end
  end
end
