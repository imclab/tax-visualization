$ ->
  #data object
  window.taxes = {}
  window.apis = {}
  $(window).bind 'got_items', ->
    showTaxes(data)
  
  window.defaults =
    year: [1984..2015]
    type: [0..3]
    sortby: [0..3] #don't care about this yet
    sortdir: false #don't care about this yet
    income: 50000
    filing: [0..3]
    budgetGroup: ["agency", "bureau", "function", "subfunction"]
    receiptGroup: ["agency", "bureau", "category", "subcategory"]
    showChange: 0
    showExtra: 0
 
  defaultAttribs =
    budgetAccount: ["year", "type", "filing"]
    budgetTotal: ["year", "type", "filing", "budgetGroup"]
    receiptAccount: ["year", "type", "filing"]
    receiptTotal: ["year", "type", "filing", "receiptGroup"]
    taxRates: ["year", "type"]
    population: ["year"]
    inflation: ["year"]
    gdp: ["year"]
    debt: ["year"]

  defaultLabels =
    type: ["All", "Mandatory", "Discretionary", "Net_Interest"]
    filing: ["Single", "Married_Jointly", "Married_Seperate", "Head_of_Household"]

  ###
  taxTypes =
    budgetAccount: "getBudgetAccount/"
    budgetTotal: "getBudgetAggregate/"
    receiptAccount: "getReceiptAccount/"
    receiptTotal: "getReceiptAggregate/"
    population: "getPopulation/"
    inflation: "getInflation/"
    gdp: "getGDP/"
    debt: "getDebt/"
    taxRates: "getTaxRates/"
  ###

  taxTypes =
    budgetTotal: "getBudgetAggregate/"

  query = (key, val, counter) ->
    if counter is 0
      return "?#{key}=#{val}"
    else
      return "&#{key}=#{val}"

  setParams = (params) ->
    paramString = ""
    i = 0
    for key, val of params
      paramString += query(key, val, i)
      i++
    if not params? #default calls year and income
      paramString += query("year", "2010", 0)
      paramString += query("income", "50000", 1)
      paramString += query("showChange", 1, 1)
      paramString += query("showExtra", 1, 1)
    else #include income, showChange and showExtra
      if not _.include(_.keys(params), "income")
        paramString += query("income", "50000", 1)
      if not _.include(_.keys(params), "showChange")
        paramString += query("showChange", 1, 1)
      if not _.include(_.keys(params), "showExtra")
        paramString += query("showExtra", 1, 1)
    return paramString

  setType = (typeName) ->
    typeString = taxTypes[typeName]
    taxes.type = typeName
    taxes[typeName] = {}
    return typeString

  getValueLabel = (paramName, i) ->
    if defaultLabels[paramName]?
      return defaultLabels[paramName][i]
    else
      return i

  getData = (api, paramInfo, show) ->
    Ajax.get(api, (data) ->
      xml = data
      if typeof data == 'string'
        xml = stringToXml(data)
      window.items = xml.getElementsByTagName('item')
      mapTaxes(xml.getElementsByTagName('item'), paramInfo)
      if (show)
        $(window).trigger('got_items', [paramInfo[0]])
      print 'Done.'
    )
 
  window.apiList = {}
  paramList = (paramNames, base, typeKey) ->
    #Generates a list of api url strings for each value of parameter
    #assumes no parameters have been specified from console
    for paramName in paramNames
      for i in defaults[paramName]
        #TODO: do boolean includes with multiple params
        params = {}
        if paramName in ["budgetGroup", "receiptGroup"]
          #special case for totals
          paramName = "group"
        valueLabel = getValueLabel(paramName, i)
        if not apiList[valueLabel]?
          apiList[valueLabel] = []
        params[paramName] = i
        apiList[valueLabel].push base + setType(typeKey) + setParams(params)
        params = undefined
    return apiList
 
  window.getTaxes = (typeName, params) ->
    print 'Loading ' + typeName + '...'
    base = "http://www.whatwepayfor.com/api/"
    if !taxTypes[typeName]
      typeName = "budgetAccount"
    #TODO: update input of typeName
    api  = base + setType(typeName) + setParams(params)
    getData(api, typeName, true)
    print '...'

  window.getAllTaxes = (params) ->
    #Get a data from a list of all api calls
    print 'Loading all taxes, please wait...'
    base = "http://www.whatwepayfor.com/api/"
    i = 0
    for typeKey in _.keys(taxTypes)
      apiList = paramList(defaultAttribs[typeKey], base, typeKey)
      for attrib of apiList
        #map type and attributes to api 
        for api in apiList[attrib]
          apis[i] = [api, typeKey, attrib]
          i++
    for a of apis
      getData(_.first(apis[a]), _.rest(apis[a]), false)
    print '...'
  
  # Shortcut functions
  window.getPopulation = (params) ->
    getTaxes("population", params)

  window.getInflation = (params) ->
    getTaxes("inflation", params)

  window.getGdp = (params) ->
    getTaxes("gdp", params)

  window.getDebt = (params) ->
    getTaxes("debt", params)

  window.getTaxRates = (params) ->
    getTaxes("taxRates", params)

  nabItem = (method, account, attribute) ->
    return items.item(account).attributes.item(attribute)[method]

  mapTaxes = (items, callInfo) ->
    # Converts the xml to json object
    # Call info is type, param
    typeName = callInfo[0]
    params = callInfo[1]
    if not taxes[typeName]?
      taxes[typeName] = {}
    if not taxes[typeName][params]?
      taxes[typeName][params] = []
    for item, i in items
      taxes[typeName][params].push mapAttribs(i)
  
  mapAttribs = (i) ->
    taxesObject = {}
    for a in [0...numItemAttributes i]
      taxesObject[nabItem('name',i,a)] = nabItem('value',i,a)
    return taxesObject

  numItemAttributes = (account) ->
    return items.item(account).attributes.length

  numAttributes = (type) ->
    return _.size(type)

  window.showTaxes = (typeObj) ->
    if (_.isUndefined(typeObj))
      # showTaxes works for allTaxes or specific calls
      typeObj = taxes.type
    str = "<table>"
    for attrib of typeObj
      if attrib in _.flatten([defaults.budgetGroup, defaults.receiptGroup])
        #Groups should have a new table
        str += "</table><table>" + getItemHeader typeObj[attrib][0]
        str += getItemBody attrib, typeObj
        str += "</table>"
      else
        str += getItemBody attrib, typeObj
    str += "</table>"
    printTaxes str

  getItemBody = (attrib, typeObj) ->
    str = ''
    #TODO: make a check for if attrib is an object
    for i in [0...numAttributes(typeObj[attrib])]
      curObj = typeObj[attrib][i]
      str += getItemRow(curObj)
    return str

  getItemRow = (type) ->
    str = "<tr>"
    for value in _.values(type)
      str += "<td>" + value + "</td>"
    str += "</tr>"
    return str

  getItemHeader = (type) ->
    str = "<tr>"
    for key in _.keys(type)
      str += "<th>" + key + "</th>"
    str += "</tr>"
    return str

  printTaxes = (str) ->
    $('#tables').html str
    if !($('#tables').is(':visible'))
      $('#tables').fadeToggle()
      $('#canvas').fadeToggle()

  window.getColumn = (typeObj, attr) ->
    # This outputs a list for graphing
    col = []
    for i of typeObj
      col.push typeObj[i][attr]
    return col
