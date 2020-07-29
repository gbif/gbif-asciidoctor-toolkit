# glossary-treeprocessor.rb: Apply roles to crossreferences to the glossary.
#
# Copyright 2020 Global Biodiversity Information Facility (GBIF)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require 'asciidoctor/extensions'

include Asciidoctor

Extensions.register do
  treeprocessor GlossaryTreeprocessor
end

class GlossaryTreeprocessor < Extensions::Treeprocessor
  @@replacements = []

  # Add a reference identifier to the list
  def addG line
    line.match(/\[\[(.*)\]\]/) { |m|
      puts "Added #{m[1]} to glossary #{@@replacements}"
      mt = m.captures[0]
      @@replacements.append(mt.gsub(/[ _-]/, '[ _-]'))
    }
  end

  # Replace any <<crossreferences>> with a similar crossreference, but with a role.
  def replaceG line
    @@replacements.map {|r|
      line = line.gsub(/<<(#{r}),?(.*?)>>/i, ' xref:\1[\2,role=glossary]')
    }
    line
  end

  # Look through the glossary, and extract the reference identifiers
  def buildGlossary block
    block.find_by(context: :dlist).each do |dlist|

      dlist.items.each do |item|
        i = item[0][0]
        s = []
        s.replace(i.subs)
        s.map{|ss| i.remove_sub(ss)}
        text = i.text
        #puts "Glossary definition item #{text}"
        addG(text)
        s.map{|ss| i.subs.append(ss)}

      end
    end
  end

  # Recurse the document tree, processing any text to find glossary crossreferences.
  def traverse block
    #puts ""
    #puts "#{block.class}"
    # Check for :macros sub.
    if defined? block.subs then
      if block.sub?(:macros) then
        s = []
        s.replace(block.subs)
        s.map{|ss| block.remove_sub(ss)}

        if defined? block.lines then
          #puts "CONTENT1 #{block.lines}"
          block.lines = block.lines.map{|l| l = replaceG(l)}
        end
        if defined? block.text then
          text = block.text
          #puts "CONTENT2 #{block.text}"
          block.text = replaceG(block.text)
        end

        s.map{|ss| block.subs.append(ss)}
      end
    end

    if ::Array === block then
      #puts "#{block[0][0].class}"
      traverse(block[0][0])
      #puts "#{block[1].class}"
      traverse(block[1])
    else
      #puts "#{block.id}, #{block.context}"

      if block.block? and block.content_model == :compound and block.blocks? then
        block.blocks.each do |b|
          traverse(b)
        end
      end
    end
  end

  def process document

    document.blocks.each do |block|
      if block.id == "glossary" then
        buildGlossary block
      end
    end

    document.blocks.each do |p|
      traverse(p)
    end

  end
end
