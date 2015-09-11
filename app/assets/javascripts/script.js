  var uber = {

    agency: "BART",

    current_route: "",

    route_code: "",

    getRoutes: function(arr){
      var options = ""
      for (var r = 0; r < arr[0].length; r++) {
        // options += "<option value='"+arr[0][r]+"' code='"+arr[1][r]+"'>"+arr[0][r]+"</option>"
        options += "<li class='pure-menu-item'><a class='pure-menu-link'value='"+arr[0][r]+"' code='"+arr[1][r]+"'>"+arr[0][r]+"</a></li>"
      };
      return options
    },

    getStops: function(arr){
      var options = ""
      for (var r = 0; r < arr[0].length; r++) {
        options += '<li class="pure-menu-item"><a href="#" class="pure-menu-link" value="'+arr[0][r]+'" code="'+arr[1][r]+'">'+arr[0][r]+'</a></li>'
      };
      return options
    },

    buildTable: function(json){
      $('table').empty()
      console.log(json)
      str = "<tr><th>Route</th><th>Next Train</th><th>2nd Train</th><th>3rd Train</th></tr>"
      for (var i = 0; i < json.length; i++) {
        if (json[i][1].length == 0) continue;
        str += "<tr><td>"+json[i][0]+"</td>"
        for (var j = 0; j < 3; j++) {
          if (json[i][1][j] != undefined ) {
            str+= "<td>"+json[i][1][j]+"</td>"
          } else { str += "<td></td>"}

        };
        str += "</tr>"
      };
      $('table').append(str)
    }
  };


  var getStops = function() {
      $.get('/stops', uber.agency+"~"+uber.route_code, function(json){
      $('#stops-select').empty()
      $('#stops-select').append(uber.getStops(json))
      stopListener();
    }, "json")
  }

  var stopListener = function(){
    $('.stops-menu').next().find('a').click(function(){
      $.get('/departures', uber.agency+"|"+$(this).text(),
      function(json){
        console.log(json)
        uber.buildTable(json)
      },
    "json")
    })
  }

$(document).ready(

  function(){
  var clickListener = function(){
    $('a').click(function(){
      uber.current_route = $(this).text()+""
      uber.route_code = $(this).attr('code')
      getStops();
      $('a.stops-menu').text("Now select a stop");
    })
  }


  $.get('/routes', uber.agency, function(json){
    $('#routes-select').empty()
    $('#routes-select').append(uber.getRoutes(json))
    clickListener();
  }, "json")






})
