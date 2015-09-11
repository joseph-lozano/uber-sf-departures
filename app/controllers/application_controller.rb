require 'open-uri'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def index

    @agencies = get_agencies

    # get_BART(origin)

  end



  def stops

    @all = get_all_stops

    render json: @all

  end

  def nearest_bart


    origins = params.keys[0]


    @nearest = [get_BART(origins)]

    @nearest

    render json: @nearest



  end


  def departures


    locus =  params.keys[0].split("|")

    @departures = get_next_departures_by_stop_name(locus[0], locus[1]).to_json

    render json: @departures

  end

  private

  def get_next_departures_by_stop_name(agency, stop)
    url = "http://services.my511.org/Transit2.0/GetNextDeparturesByStopName.aspx?token=#{Figaro.env.token}&agencyName=#{agency}&stopName=#{stop}"
    doc = Nokogiri::XML(open(url))
    routes = doc.xpath('//Route')
    route_names = routes.map do |r|
      r.attr('Name')
    end

    next_departures = [[],[]]

    routes.each_with_index do |route, idx|
      next_departures[0].push(route_names[idx])

      times = []
      route.xpath("//*[@Name='#{route_names[idx]}']//DepartureTime").children.each do |node|
        times.push(node.text)
      end
      next_departures[1].push(times)

    end
    next_departures = next_departures.transpose

      next_departures.each do |stop|
        stop[1].map! do |time|
          t = (Time.now() + time.to_i*60)
          time = t.strftime('%I:%M:%S %p')
        end
      end

      next_departures

  end

  def get_agencies
    url = "http://services.my511.org/Transit2.0/GetAgencies.aspx?token=#{Figaro.env.token}"
    doc = Nokogiri::XML(open(url))
    agencies = doc.xpath('//*[@Name]')

    agencies.map do |a|
      a.attr('Name')
    end
  end


  def get_routes_for(agency)
    url = "http://services.my511.org/Transit2.0/GetRoutesForAgency.aspx?token=#{Figaro.env.token}&agencyName=#{agency}"
    doc = Nokogiri::XML(open(url))

    has_direction = doc.xpath('//*[@HasDirection]')

    codes  = doc.xpath('//*[@Code]')
    names = doc.xpath('//*[@Name]')

    names = names.map do |r|
      r.attr('Name')
    end

    names.shift()

    codes = codes.map do |r|
      r.attr('Code')
    end

    direction = has_direction.map do |r|
      r.attr('HasDirection')
    end

    return [names, codes, direction]
  end

  def get_all_stops()
    stops = get_routes_for("BART")
    names = stops[0]
    codes = stops[1]

    routeIDFs = []

    codes.each do |code|
      routeIDFs.push("BART"+"~"+code.to_s)
    end

    routeIDFs = routeIDFs.join("|")

   url = "http://services.my511.org/Transit2.0/GetStopsForRoutes.aspx?token=#{Figaro.env.token}&routeIDF=#{routeIDFs}"
   doc = Nokogiri::XML(open(url))

   stop_codes  = doc.xpath('//*[@StopCode]')
   names = doc.xpath('//*[@name]')

    names = names.map do |r|
      r.attr('name')
    end

    stop_codes = stop_codes.map do |r|
      r.attr('StopCode')
    end

   stops = [names, stop_codes].transpose.sort {|a,b| a[1] <=> b[1]}.uniq!

   return remove_duplicates(stops).transpose
  end

  def get_stops_for_route(routeIDF)
    url = "http://services.my511.org/Transit2.0/GetStopsForRoute.aspx?token=#{Figaro.env.token}&routeIDF=#{routeIDF}"
    doc = Nokogiri::XML(open(url))

    stop_codes  = doc.xpath('//*[@StopCode]')
    stops = doc.xpath('Stop')
    names = doc.xpath('//*[@name]')

    names = names.map do |r|
      r.attr('name')
    end

    stop_codes = stop_codes.map do |r|
      r.attr('StopCode')
    end

    return [names, stop_codes]
  end

  def remove_duplicates(arr)

    names = arr.transpose[0]

    codes = arr.transpose[1]

    uniqs = [[],[]]

    names.each_with_index do |n, i|
      unless uniqs[0].include?(n)
        uniqs[0].push(n)
        uniqs[1].push(codes[i])
      end
    end

    uniqs

  end

  def get_BART(origins)

    stops = get_all_stops

    destinations = []

    stops.each do |s|
      s[0]
      destinations.push(s[0]+" BART")
    end



    destinations = destinations.join("|")

    destinations.gsub!(/\(([^)]+)\)/,"")

    p url = "https://maps.googleapis.com/maps/api/distancematrix/xml?origins=#{origins}&destinations=#{destinations}&key=#{Figaro.env.google_matrix}"

    doc = Nokogiri::XML(open(url))

    destination_addresses = []
    travel_times = []

    doc.xpath('//destination_address').each do |node|
      destination_addresses.push(node.text)
    end

    doc.xpath('//duration//value').each do |node|
    travel_times.push(node.text.to_i)
    end

    idx = travel_times.each_with_index.min[1]

    closest_station = destination_addresses[idx]

  end

end
