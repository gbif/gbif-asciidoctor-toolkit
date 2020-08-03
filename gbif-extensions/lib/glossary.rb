# coding: utf-8
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

  # Look through the glossary block, and extract any anchor identifiers
  def find_glossary_anchor_identifiers glossary_block
    glossary_block.find_by(context: :dlist).each do |dlist|
      dlist.items.each do |item|
        #puts "Glossary definition item #{item[0][0]}"
        extract_glossary_anchor_identifier(item[0][0].text_source)
      end
    end
  end

  # Extract an anchor identifier from a glossary definition list item
  def extract_glossary_anchor_identifier line
    # TODO: use InlineAnchorRx
    line.match(/\[\[([^,]+)(,.+|)\]\]/) { |m|
      mt = m.captures[0]
      #puts "Anchor “#{mt}” is for a glossary definition."
      @@replacements.append(mt.gsub(/[ _-]/, '[ _-]'))
    }
  end

  # Traverse the document tree, processing any text to find and replace glossary crossreferences.
  def add_role_to_glossary_crossreferences block

    # Description lists contain arrays.
    unless ::Array === block
      # Replace title
      if block.title? then
        block.title = add_role(block.title_source)
      end

      if ::Table::Cell === block then
        unless block.style == :asciidoc
          unless block.source.nil? then
            block.text = add_role(block.source)
          end
        end
      elsif defined? block.subs then
        # Check for :macros sub, if it is not enabled then crossreferences aren't being parsed anyway.
        if block.sub?(:macros) then
          if defined? block.lines_source then
            block.lines = block.lines_source.map{|l| l = add_role(l)}
          end

          if defined? block.text_source then
            unless block.text.nil? then
              block.text = add_role(block.text_source)
            end
          end
        end
      end
    end

    if ::Array === block then
      add_role_to_glossary_crossreferences(block[0][0])

      if defined? block[1] then
        add_role_to_glossary_crossreferences(block[1])
      end
    else

      if block.block? && block.content_model == :compound then
        if block.blocks? then
          block.blocks.each do |b|
            add_role_to_glossary_crossreferences(b)
          end
        elsif ::Table === block then
          block.rows.head.map{|tr|
            tr.map{|td| add_role_to_glossary_crossreferences(td)}
          }
          block.rows.body.map{|tr|
            tr.map{|td| add_role_to_glossary_crossreferences(td)}
          }
          block.rows.foot.map{|tr|
            tr.map{|td| add_role_to_glossary_crossreferences(td)}
          }
        elsif ::Table::Cell === block then
          if block.style == :asciidoc then
            add_role_to_glossary_crossreferences(block.inner_document)
          end
        end
      end
    end
  end

  # Replace any <<crossreferences>> with a similar crossreference, but with a role.
  # I am surprised not to find a better way to do this, e.g. an object representing
  # the crossreference macro within the line.
  def add_role line
    anchor_patterns = "(" + @@replacements.join("|") + ")"
    line = line.gsub(/<<#{anchor_patterns}(,[^,]+?|)>>/i) {|s|
      ref = $1
      reftext = $2.gsub(/^,/, '')
      "xref:#{ref}[#{reftext},role=glossary]"
    }
    line
  end

  def process document
    document.blocks.each do |block|
      if block.id == "glossary" then
        find_glossary_anchor_identifiers block
      end
    end

    unless @@replacements.empty?
      document.blocks.each do |p|
        add_role_to_glossary_crossreferences(p)
      end
    end
  end
end

# Rather than disabling inline substitutions before reading text:
#   s = []
#   s.replace(block.subs)
#   s.map{|ss| block.remove_sub(ss)}
#   block.text
#   s.map{|ss| block.subs.append(ss)}
# add methods to get the source text without substitutions applied.
#
# See also https://discuss.asciidoctor.org/Changing-text-content-in-a-TreeProcessor-extension-td8115.html
class AbstractBlock
  def title_source
    @title
  end
end

class Block
  def lines_source
    @lines
  end
end

class ListItem
  def text_source
    @text
  end
end

class Asciidoctor::Table::Cell
  def source
    @text
  end
end
