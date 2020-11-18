#!/usr/bin/env ruby
# coding: utf-8

# AmRRON, EJ-01
# v1.0

require 'optimist'
require 'pry_debug'

in_file="/home/jfrancis/.config/JS8Call.ini" # xxx

# These are the command line options.
opts=Optimist::options do
  opt :grid, "Grid square", :type => :string
  opt :twitter, "Twitter status (R, Y, G (default G))", :type => :string
  opt :facebook, "Facebook status (R, Y, G (default G))", :type => :string
  opt :instagram, "Instagram status (R, Y, G (default G))", :type => :string
  opt :linkedin, "LinkedIn status (R, Y, G (default G))", :type => :string
  opt :parler, "Parler status (R, Y, G (default G))", :type => :string
  opt :fox_news, "Fox News status (R, Y, G (default G))", :type => :string
  opt :cnn_news, "CNN News status (R, Y, G (default G))", :type => :string
  opt :msnbc_news, "MSNBC News status (R, Y, G (default G))", :type => :string
  opt :drudge_report, "Drudge Report status (R, Y, G (default G))", :type => :string
  opt :liberty_daily, "The Liberty Daily status (R, Y, G (default G))", :type => :string
  opt :huff_post, "The Huffington Post status (R, Y, G (default G))", :type => :string
end

if opts[:grid_given]
  grid=opts[:grid]
else
  grid="<GRID>"
end

if opts[:twitter_given]
  if(opts[:twitter].upcase=="G")
    twitter="00"
  elsif(opts[:twitter].upcase=="Y")
    twitter="01"
  elsif(opts[:twitter].upcase=="R")
    twitter="10"
  else
    puts("invalid option for --twitter")
    exit
  end
else
  twitter="00"
end

if opts[:facebook_given]
  if(opts[:facebook].upcase=="G")
    facebook="00"
  elsif(opts[:facebook].upcase=="Y")
    facebook="01"
  elsif(opts[:facebook].upcase=="R")
    facebook="10"
  else
    puts("invalid option for --facebook")
    exit
  end
else
  facebook="00"
end

if opts[:instagram_given]
  if(opts[:instagram].upcase=="G")
    instagram="00"
  elsif(opts[:instagram].upcase=="Y")
    instagram="01"
  elsif(opts[:instagram].upcase=="R")
    instagram="10"
  else
    puts("invalid option for --instagram")
    exit
  end
else
  instagram="00"
end

if opts[:linkedin_given]
  if(opts[:linkedin].upcase=="G")
    linkedin="00"
  elsif(opts[:linkedin].upcase=="Y")
    linkedin="01"
  elsif(opts[:linkedin].upcase=="R")
    linkedin="10"
  else
    puts("invalid option for --linkedin")
    exit
  end
else
  linkedin="00"
end

if opts[:parler_given]
  if(opts[:parler].upcase=="G")
    parler="00"
  elsif(opts[:parler].upcase=="Y")
    parler="01"
  elsif(opts[:parler].upcase=="R")
    parler="10"
  else
    puts("invalid option for --parler")
    exit
  end
else
  parler="00"
end

if opts[:fox_news_given]
  if(opts[:fox_news].upcase=="G")
    fox_news="00"
  elsif(opts[:fox_news].upcase=="Y")
    fox_news="01"
  elsif(opts[:fox_news].upcase=="R")
    fox_news="10"
  else
    puts("invalid option for --fox-news")
    exit
  end
else
  fox_news="00"
end

if opts[:cnn_news_given]
  if(opts[:cnn_news].upcase=="G")
    cnn_news="00"
  elsif(opts[:cnn_news].upcase=="Y")
    cnn_news="01"
  elsif(opts[:cnn_news].upcase=="R")
    cnn_news="10"
  else
    puts("invalid option for --cnn-news")
    exit
  end
else
  cnn_news="00"
end

if opts[:msnbc_news_given]
  if(opts[:msnbc_news].upcase=="G")
    msnbc_news="00"
  elsif(opts[:msnbc_news].upcase=="Y")
    msnbc_news="01"
  elsif(opts[:msnbc_news].upcase=="R")
    msnbc_news="10"
  else
    puts("invalid option for --msnbc-news")
    exit
  end
else
  msnbc_news="00"
end

if opts[:drudge_report_given]
  if(opts[:drudge_report].upcase=="G")
    drudge_report="00"
  elsif(opts[:drudge_report].upcase=="Y")
    drudge_report="01"
  elsif(opts[:drudge_report].upcase=="R")
    drudge_report="10"
  else
    puts("invalid option for --drudge-report")
    exit
  end
else
  drudge_report="00"
end

if opts[:liberty_daily_given]
  if(opts[:liberty_daily].upcase=="G")
    liberty_daily="00"
  elsif(opts[:liberty_daily].upcase=="Y")
    liberty_daily="01"
  elsif(opts[:liberty_daily].upcase=="R")
    liberty_daily="10"
  else
    puts("invalid option for --liberty-daily")
    exit
  end
else
  liberty_daily="00"
end

if opts[:huff_post_given]
  if(opts[:huff_post].upcase=="G")
    huff_post="00"
  elsif(opts[:huff_post].upcase=="Y")
    huff_post="01"
  elsif(opts[:huff_post].upcase=="R")
    huff_post="10"
  else
    puts("invalid option for --huff-post")
    exit
  end
else
  huff_post="00"
end

puts("#{grid} #{(twitter+facebook+instagram+linkedin+parler+fox_news+cnn_news+msnbc_news+drudge_report+liberty_daily+huff_post).to_i(2).to_s(16)}")
