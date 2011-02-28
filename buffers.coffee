buffers =
  splatter: '''
    n = 16

    createAxis("100%","100%",40)

    cube = (x) -> pow(x,3)
    pos  =-> 500 + cube (15 * (random()-0.5))
    size =-> cube 4.5*random()

    circles = set()
    for i in [1..n]
      circles.push circle(pos(),pos(),size())
      .attr
        fill: color = getColor()
        opacity: 0.6
        "stroke": "#333"
        "stroke-width": 1
        "stroke-opacity": 0

    circles.mouseover ->
      this.attr
        "stroke-opacity": 1
        opacity:0.85
        cursor: "pointer"
    circles.mouseout ->
      this.anim
        "stroke-opacity": 0
        opacity:0.6
        cursor: "pointer"
        duration: 140
            '''
  spiral:   '''
    n = 100

    createAxis("100%","100%",40)

    posx = (x) -> 800 + 9*i*sin(pi/12*i)
    posy = (x) -> 500 + 9*i*cos(pi/12*i)
    size = (x) -> x/2 + 1

    circles = set()
    for i in [1..n]
      circles.push circle(posx(i),posy(i),size(i))
      .attr
        fill: color = getColor()
        opacity: 0.6
        "stroke": "#333"
        "stroke-width": 1
        "stroke-opacity": 0
            '''
  chart:    '''
    values = []
    dotsy = []
    clr = []
    c = path("M0,0").attr
      fill: "none"
      "stroke-width": 3

    for i in [0..12]
      values[i] = randomPath(30, i, dotsy)
      clr[i] = Raphael.getColor()
      c.attr({path: values[i], stroke: clr[i]})
            '''
  equation: '''
    eq = (x) -> sin(x)  # equation
    min = 0             # minimum
    max = 4*pi          # maximum
    inc = pi/24         # increment size
    width = 600         # window width
    zoom = 120          # amplitude multiplier
    ox = 400            # x of origin
    oy = 400            # y of origin

    num = (max-min) / inc
    points = []
    point = (x,y) -> circle(x,y,1)
    for i in [0..num]
      x = (inc*i + min)
      y = eq x
      points.push point(x*(width/num/inc) + ox, y*zoom + oy)
            '''

$ ->
  flipper = (button, panel, showmsg, hidemsg) ->
    $(button).toggle( ->
      $(this).html hidemsg
      $(panel).fadeIn()
    , ->
      $(this).html showmsg
      $(panel).fadeOut()
    )

  flipper("#show",
          "#code",
          "Code",
          "Hide Code")
  flipper("#cons",
          "#console",
          "Console",
          "Hide Console")
  flipper("#tut",
          "#tutorial",
          "Tutorial",
          "Hide Tutorial")
  flipper("#out",
          "#canvas",
          "Output",
          "Hide Output")

  $("#buffers").change( ->
    buffer = $(this).val()
    $("#code").html buffers[buffer]
  )

  # When buffer selected on reload
  buffer = $("#buffers").val()
  $("#code").html buffers[buffer]

  # Hacks

  $('#console').height($(window).height()).fadeIn(200)
  $('#output').css 'max-height': $(window).height() - 144

  # End hacks
  
  window.params =
    year: 2010     # 1984 - 2015
    type: 0        # 0 - 3
    sortdir: false
    income: 5000000
    filing: 0      # 0 - 4
    budgetGroup: ["agency", "bureau", "function", "subfunction"]
    receiptGroup: ["agency", "bureau", "category", "subcategory"]
    showChange: false,
    showExtra: false
    function: 0
    subfunction: 0
    category: 0
    subcategory: 0

  window.dvc = (type) ->
    base = "http://www.whatwepayfor.com/api/"
    call = "?year=" + params.year +
           "&type=" + params.type +
           "&sortdir=" + (params.sortdir * 1) +
           "&filing=" + params.filing +
           "&showChange=" + (params.showChange * 1) +
           "&showExtra="  + (params.showExtra * 1)

    typeString = ""
    switch type
      when "budgetAccount"
        typeString = "getBudgetAccount"
        call += "&function=" + params.function +
                "&subfunction=" + params.subfunction +
                "&income=" + params.income
      when "budgetAggregate"
        typeString = "getBudgetAggregate"
        call += "&function=" + params.function +
                "&subfunction=" + params.subfunction +
                "&income=" + params.income +
                "&group=" + params.budgetGroup[2]
      when "receiptAccount"
        typeString = "getReceiptAccount"
        call += "&category=" + params.category +
                "&subcategory=" + params.subcategory
      when "receiptAggregate"
        typeString = "getReceiptAggregate"
        call += "&category=" + params.category +
                "&subcategory=" + params.subcategory +
                "&group=" + params.receiptGroup[2]
      else typeString = "getBudgetAccount"
    typeString += "/"
       
    api  = base + typeString + call
    Ajax.get(api, success)
    
  success = (data) ->
    xml = data
    if typeof data == 'string'
      xml = stringToXml(data)
    window.items = xml.getElementsByTagName('item')

  window.expose = (x) ->
    str = ""
    for i in [0..13]
      str += "<b>" + (nab('name', x, i)) + "</b>: " + (nab('value', x, i)) + "<br/>"
    $('#canvas').html str

  window.taxes =
    budgetAccount:
      year: 2010
      income: 50000
      exacttax: 0
      function: 0
      subfunction: 0
      agency: 0
      bureau: 0
      account: 0
      functionId: 1000
      subfunctionId: 1000
      agencyId: 1000
      bureauId: 1000
      accountId: 1000
      adjustInflationYear: 2010
      type: 0
      sortby: 0
      sortdir: 0
      filing: 0
      selfEmployed: 0
      showExtra: 0
      showChange: 0
      spendingType: 1
      onBudget: true
      total: 0
      deltaTotal: 0
      deltaPercent: 0
      myCost: 0
      perCapita: 0
      gdpPercent: 0
    budgetAggregate:
      group:
        function:
          dimensionName: ""
          dimensionId: 0
          spendingType: 0
          total: 0
          deltaTotal: 0
          deltaPercent: 0
          myCost: 0
        subfunction:
          dimensionName: ""
          dimensionId: 0
          spendingType: 0
          total: 0
          deltaTotal: 0
          deltaPercent: 0
          myCost: 0
        agency:
          dimensionName: ""
          dimensionId: 0
          spendingType: 0
          total: 0
          deltaTotal: 0
          deltaPercent: 0
          myCost: 0
        bureau:
          dimensionName: ""
          dimensionId: 0
          spendingType: 0
          total: 0
          deltaTotal: 0
          deltaPercent: 0
          myCost: 0
      year: 2010
      income: 50000
      exacttax: 0
      function: 0
      subfunction: 0
      agency: 0
      bureau: 0
      account: 0
      functionId: 1000
      subfunctionId: 1000
      agencyId: 1000
      bureauId: 1000
      accountId: 1000
      adjustInflationYear: 2010
      type: 0
      sortby: 0
      sortdir: 0
      filing: 0
      selfEmployed: 0
      showExtra: 0
      showChange: 0
      spendingType: 1
      onBudget: true
      total: 0
      deltaTotal: 0
      deltaPercent: 0
      myCost: 0
      perCapita: 0
      gdpPercent: 0
    receiptAccount:
      year: 2010
      exacttax: 0
      category: 0
      subcategory: 0
      agency: 0
      bureau: 0
      account: 0
      categoryId: 1000
      subcategoryId: 1000
      agencyId: 1000
      bureauId: 1000
      accountId: 1000
      adjustInflationYear: 2010
      type: 0
      sortby: 0
      sortdir: 0
      filing: 0
      selfEmployed: 0
      showExtra: 0
      showChange: 0
      spendingType: 1
      onBudget: true
      total: 0
      deltaTotal: 0
      deltaPercent: 0
      myCost: 0
      perCapita: 0
      gdpPercent: 0
    receiptAggregate:
      group:
        category:
          dimensionName: ""
          dimensionId: 0
          spendingType: 0
          total: 0
          deltaTotal: 0
          deltaPercent: 0
          myCost: 0
        subcategory:
          dimensionName: ""
          dimensionId: 0
          spendingType: 0
          total: 0
          deltaTotal: 0
          deltaPercent: 0
          myCost: 0
        agency:
          dimensionName: ""
          dimensionId: 0
          spendingType: 0
          total: 0
          deltaTotal: 0
          deltaPercent: 0
          myCost: 0
        bureau:
          dimensionName: ""
          dimensionId: 0
          spendingType: 0
          total: 0
          deltaTotal: 0
          deltaPercent: 0
          myCost: 0
      year: 2010
      exacttax: 0
      category: 0
      subcategory: 0
      agency: 0
      bureau: 0
      account: 0
      categoryId: 1000
      subcategoryId: 1000
      agencyId: 1000
      bureauId: 1000
      accountId: 1000
      adjustInflationYear: 2010
      type: 0
      sortby: 0
      sortdir: 0
      filing: 0
      selfEmployed: 0
      showExtra: 0
      showChange: 0
      spendingType: 1
      onBudget: true
      total: 0
      deltaTotal: 0
      deltaPercent: 0
      myCost: 0
      perCapita: 0
      gdpPercent: 0