module ApplicationHelper


  def get_next_departures_by_stop_name(agency, stop)
    "http://services.my511.org/Transit2.0/GetNextDeparturesByStopName.aspx?token=#{Figaro.env.token}&agencyName=#{agency}&stopName=#{stop}"
  end

  def get_agencies
    "http://services.my511.org/Transit2.0/GetAgencies.aspx?token=#{Figaro.env.token}"
  end

  def get_routes_for_agency(agency)
    "http://services.my511.org/Transit2.0/GetRoutesForAgencies.aspx?token=#{Figaro.env.token}&agencyName=#{agency}"
  end

  def get_stops_for_route(routeIDF)
    "http://services.my511.org/Transit2.0/GetStopsForRoute.aspx?token=#{Figaro.env.token}&routeIDF=#{routeIDF}"
  end


end
