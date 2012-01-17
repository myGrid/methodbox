# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rchardet}
  s.version = "1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jeff Hodges"]
  s.date = %q{2009-07-19}
  s.email = %q{jeff at somethingsimilar dot com}
  s.extra_rdoc_files = ["README", "COPYING"]
  s.files = ["lib/rchardet/big5freq.rb", "lib/rchardet/big5prober.rb", "lib/rchardet/chardistribution.rb", "lib/rchardet/charsetgroupprober.rb", "lib/rchardet/charsetprober.rb", "lib/rchardet/codingstatemachine.rb", "lib/rchardet/constants.rb", "lib/rchardet/escprober.rb", "lib/rchardet/escsm.rb", "lib/rchardet/eucjpprober.rb", "lib/rchardet/euckrfreq.rb", "lib/rchardet/euckrprober.rb", "lib/rchardet/euctwfreq.rb", "lib/rchardet/euctwprober.rb", "lib/rchardet/gb2312freq.rb", "lib/rchardet/gb2312prober.rb", "lib/rchardet/hebrewprober.rb", "lib/rchardet/jisfreq.rb", "lib/rchardet/jpcntx.rb", "lib/rchardet/langbulgarianmodel.rb", "lib/rchardet/langcyrillicmodel.rb", "lib/rchardet/langgreekmodel.rb", "lib/rchardet/langhebrewmodel.rb", "lib/rchardet/langhungarianmodel.rb", "lib/rchardet/langthaimodel.rb", "lib/rchardet/latin1prober.rb", "lib/rchardet/mbcharsetprober.rb", "lib/rchardet/mbcsgroupprober.rb", "lib/rchardet/mbcssm.rb", "lib/rchardet/sbcharsetprober.rb", "lib/rchardet/sbcsgroupprober.rb", "lib/rchardet/sjisprober.rb", "lib/rchardet/universaldetector.rb", "lib/rchardet/utf8prober.rb", "lib/rchardet.rb", "README", "COPYING"]
  s.homepage = %q{http://github.com/jmhodges/rchardet/tree/master}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rchardet}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Character encoding auto-detection in Ruby. As smart as your browser. Open source.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
