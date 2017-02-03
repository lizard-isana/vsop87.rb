#!/usr/local/bin/ruby
require 'date'
require "cgi-lib"


class Clock
  def initialize(date)
      date = date.utc
      @date = date
      @year,@month,@day,@hour,@min,@sec = date.year,date.month,date.day,date.hour,date.min,date.sec
      @time_in_day = @hour.to_f/24 + @min.to_f/1140 + @sec.to_f/86400
      @time_in_hour = @hour.to_f + @min.to_f/60 + @sec.to_f/3600
      @time_in_sec = @hour*3600+@min*60+@sec
  end


  def jd
    
    if @month<=2 then
      y=(@year-1).to_i
      m=(@month+12).to_i
    else
     y = @year
     m = @month
    end
    
    julian_day = (365.25*(y+4716)).floor+(30.6001*(m+1)).floor+@day-1524.5

    if julian_day<2299160.5 then
      transition_offset=0
    else
      tmp = (@year/100).floor
      transition_offset=2-tmp+(tmp/4).floor  
    end
 
    return julian_day=julian_day+transition_offset + @time_in_day
  end
end

class SplitData
  def initialize(data)
    @data_array = []
    @data = data
  end
  def split
    @data_array << @data[1..1].to_i #version
    @data_array << @data[2..2].to_i #body
    @data_array << @data[3..3].to_i #index
    @data_array << @data[4..4].to_i #alpha
    @data_array << @data[79..96].to_f #A
    @data_array << @data[97..110].to_f #B
    @data_array << @data[111..130].to_f #C
    return @data_array
  end
end

class VSOP87
  def initialize(data_set,jd)
    @data_set = data_set
    @jd = jd
  end

def load
  data_array = []
  open(@data_set) {|file|
    while line = file.gets
      if line[1..1]!="V" then
        r = SplitData.new(line)
        data_array << r.split
      end
    end
  }
  return data_array
end

def calc
  data_array = load()
  t = ((@jd -2451545.0)/365250).to_f
  v = []
  data_array.each {|data|
     i = data[2]-1
     if v[i] == nil then
       v[i] = 0
    end
      v[i] = v[i].to_f + (t**data[3])*data[4].to_f * Math.cos(data[5].to_f + data[6].to_f * t) 
  }

  return v

  end

end

#

input = CGI.new
data_set = input["f"]
print "Content-type:text/plain\n\n"
if data_set then
  if input["d"] then
    jd = input["d"].to_f
  else
    date = Time.now
    time = Clock.new(date)
    jd = time.jd
  end
  vsop = VSOP87.new(data_set,jd)
  puts "#{data_set} at JD#{jd}"
  v_array=vsop.calc
  i=0
  v_array.each {|v|
    puts "variable[#{i}] =  #{v}"
    i=i+1
  }
else
  f = open("vsop87.txt")
  description = f.read
  f.close

  print <<EOS
============
Planetary positions by VSOP87 theory
============

DESCRIPTION
===========

Loading source files of VSOP87 and calculating positions of the planet at given julian day.
You should get VSOP87 solution files from VizieR archives.
http://cdsarc.u-strasbg.fr/viz-bin/Cat?cat=VI%2f81

USAGE
=========

vsop87.rb?f=FILE_NAME(&d=JULIAN_DAY)

if you omit param "d" you will get current position.

REFERENCE
=========
VizieR Online Data Catalog: Planetary Solutions VSOP87 (Bretagnon+, 1988)
http://adsabs.harvard.edu/abs/1995yCat.6081....0B

 VizieR archives : Planetary Theories in rectangular and spherical variables: VSOP87 solution.
http://cdsarc.u-strasbg.fr/viz-bin/Cat?cat=VI%2f81

### Here is the description of VSOP87 files. ###

#{description}

EOS
  end
