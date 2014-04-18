"use strict"

#TODO Add fluid transitions when updating content
#TODO Add support for multiple instances displayed in single view
#TODO Add support for various notifications flash message for instance

TEMPLATES =
  error_500:
    template: "<div style='text-align: center;'><p style='font-size: 1.4em; line-height: 1em; margin-bottom: 15px;'>Error 500</p>{{i18n.error_message}}</div>"
    i18n:
      pl: 
        error_message: "Coś poszło nie tak"
      en: 
        error_message: "Something went wrong"
        
DEFAULTS =
  DIALOG:
    closeBtn: true    
    locale: 'en'
    padding: 15
    type: 'modal'    
    wrapperClass: ''
  MODAL:
    margin: 20
  POPUP:
    margin: 20
    position: 
      at: 'right'
      my: 'center'
  NOTIFICATION: 
    area: 'right top'
    duration: 10000


INSTANCES = 
  POPUP: []
  MODAL: []
  NOTIFICATION: []

  
    

# Mainly for collision testing
class Area
  constructor: (p1, p2, margin) ->
    m = 
      top: 0
      right: 0
      bottom: 0
      left: 0

    if typeof margin is 'number'
      m = 
        top: margin
        right: margin
        bottom: margin
        left: margin    
    else if typeof margin is 'object'
      $.extend(m, margin)

    @p1 = 
      x: p1[0] + m.left
      y: p1[1] + m.top
    @p2 = 
      x: p2[0] - m.right
      y: p2[1] - m.bottom

  detectCollisions: (area) ->
    collisions = []
    if area.width() > @width()
      collisions.push('widthExceeded')
    if area.height() > @height()
      collisions.push('heightExceeded')
    if area.p1.y < @p1.y and area.p1.y + area.height() > @p1.y
      collisions.push('topBound')
    if area.p1.y < @p2.y and area.p1.y + area.height() > @p2.y
      collisions.push('bottomBound')
    if area.p1.x < @p1.x and area.p1.x + area.width() > @p1.x
      collisions.push('leftBound')
    if area.p1.x < @p2.x and area.p1.x + area.width() > @p2.x
      collisions.push('rightBound')    
    return collisions     

  offset: (offset) ->
    if offset?
      cachedWidth = @width()
      cachedHeight = @height()
      @p1.x = offset.left if offset.left?
      @p1.y = offset.top if offset.top?
      @height(cachedHeight)
      @width(cachedWidth)
      return @
    else
      return { left: @p1.x, top: @p1.y }

  width: (val) -> 
    if val? 
      @p2.x = @p1.x + val 
      return @
    else return Math.abs(@p1.x - @p2.x)

  height: (val) -> 
    if val? 
      @p2.y = @p1.y + val 
      return @
    else return Math.abs(@p1.y - @p2.y)





class Dialog
  _$overlay = undefined
    
  _init = -> 
    _$overlay = $("<div/>").hide().addClass("uniDialog-overlay")
    $("body").append( _$overlay )
    $(document)
      .bind('mousedown.uniDialog', (e) -> $.uniDialog.closeAll() unless $(e.target).closest('.uniDialog-wrapper').length 
      ).bind('keyup.uniDialog', (e) -> $.uniDialog.closeAll() if (e.keyCode == 27))

  constructor: (name, type, data, options) ->
    self = @    
    blueprint = TEMPLATES[name]

    @type = type
    @options = $.extend true, {}, DEFAULTS.DIALOG, DEFAULTS[@type.toUpperCase()], options
    @name = name        
    @data = $.extend true, { i18n: { locale: @options.locale } }, { i18n: blueprint.i18n[@options.locale] }
    @events = blueprint.events
    @callbacks = blueprint.callbacks
    @template = blueprint.template
          
    # BUILD
    @html = {}
    @html.$content = $("<div/>").addClass("uniDialog-inner")
    @html.$wrapper = $("<div/>").addClass("uniDialog-wrapper uniDialog-locale-#{@options.locale} uniDialog-type-" + @type + " uniDialog-name-#{@name} #{@options.wrapperClass}").append($("<div class='uniDialog-outer'/>").append(@html.$content)).data('uniDialog', @)

    if @options.closeBtn
      @html.$wrapper.append("<span class='uniDialog-close'/>").find('.uniDialog-close').click -> self.close()
        
    if @type is 'popup'
      @html.$arrow = $("<div class='uniDialog-arrow-container'><div class='uniDialog-arrow-border'></div><div class='uniDialog-arrow-fill'></div></div>")
      @html.$wrapper.addClass("uniDialog-position-#{@options.position.at}").append(@html.$arrow)
      $("body").append(@html.$wrapper)

    if @type is 'modal'
      $("body").append(@html.$wrapper)

    if @type is 'notification'
      areaPositionRegExp = /^(left|center|right) (top|middle|bottom)$/
      $area = $(@options.area)
      if !$area.length and typeof @options.area is 'string'      
        areaPosition = areaPositionRegExp.exec(@options.area) || areaPositionRegExp.exec(DEFAULTS['NOTIFICATION'].area)                   
        $area = $(".uniDialog-area.area-#{areaPosition[1]}-#{areaPosition[2]}")
        if !$area.length
          $area = $('<div/>').addClass("uniDialog-area area-#{areaPosition[1]}-#{areaPosition[2]}")
          $("body").append($area)             
      $area.append(@html.$wrapper)
      setTimeout (-> self.close()), self.options.duration
      

    # BIND EVENTS    
    $.each @events, (key, f) ->
      key = key.split ' '
      eventType = key[0]
      if key.length is 2
        selector = key[1]        
        self.html.$wrapper.on "#{eventType}.uniDialog", selector, -> f.apply(self, arguments)

    INSTANCES[@type.toUpperCase()].push @
    

  close: ->
    #TODO Add fade animations        
    @html.$wrapper.remove()
    _$overlay.hide() if @type is 'modal'
    INSTANCES[@type.toUpperCase()].splice( $.inArray(@, INSTANCES[@type.toUpperCase()]), 1 )
    @trigger "afterClose"

  show: ->
    #TODO Add fade animations        
    @trigger 'beforeShow'
    @reposition()
    @html.$wrapper.removeClass('uni-popup-hidden')  


  hide: ->
    @html.$wrapper.addClass('uni-popup-hidden')

  findEl: (selector) -> 
    @html.$wrapper.find("#{selector}")

  trigger: (eventType, args...) ->    
    f = @callbacks[eventType]
    f.apply(@, args) if $.isFunction(f)

  reposition: ->
    return false if @type is 'notification'
    
    #Just for further calculations
    @html.$content.removeAttr('style')
          
    winWidth = $(window).width()
    winHeight = $(window).height()
    winOffset = 
      top: $(window).scrollTop()
      left: $(window).scrollLeft()

    popWidth = @html.$wrapper.outerWidth()
    popHeight = @html.$wrapper.outerHeight()
    popOutlineWidth = popWidth - @html.$content.outerWidth()
    popOutlineHeight = popHeight - @html.$content.outerHeight()

    _getOppositePosition = ->
      oppositePositions = 
        left: 'right'
        right: 'left'
        bottom: 'top'
        top: 'bottom'
      return oppositePositions[@options.position.at]
      
    _flipPosition = ->
      @options.position.at = _getOppositePosition.call @

      htmlClass = @html.$wrapper.attr('class').replace(/uni-popup-pos-([a-z]+)/, "uni-popup-pos-#{@options.position.at[0]}")
      @html.$wrapper.attr('class', htmlClass)    

    _resolveCollisions = (collisions, area, popArea) ->
      # TODO add scroll support
      if $.inArray('widthExceeded', collisions) >= 0
        #add horizontal scroll - temp disabling scroll
        #popArea.offset({ left: area.offset().left }).width(area.width())
        popArea.offset({ left: area.offset().left })
      else if $.inArray('leftBound', collisions) >= 0
        popArea.offset({ left: area.offset().left })
      else if $.inArray('rightBound', collisions) >= 0
        popArea.offset({ left: area.p2.x - popArea.width() })

      if $.inArray('heightExceeded', collisions) >= 0      
        #add vertical scroll - temp disabling scroll
        #popArea.offset({ top: area.offset().top }).height(area.height())
        popArea.offset({ top: area.offset().top })
      else if $.inArray('topBound', collisions) >= 0
        popArea.offset({ top: area.offset().top })
      else if $.inArray('bottomBound', collisions) >= 0
        popArea.offset({ top: area.p2.y - popArea.height() })


    _appendPopupToArea = (popArea) ->
      @html.$wrapper.css
        left: popArea.offset().left
        top: popArea.offset().top     
      @html.$content.css
        width: popArea.width() - popOutlineWidth
        height: popArea.height() - popOutlineHeight


    if @type is 'popup'
      target = $(@options.target)
      targetHeight = target.outerHeight()
      targetWidth = target.outerWidth()
      targetOffset = target.offset()


      collisionsArea =
        top: new Area( [winOffset.left, winOffset.top], [winWidth + winOffset.left, targetOffset.top], 15 )
        right: new Area( [targetOffset.left + targetWidth, winOffset.top], [winWidth + winOffset.left, winHeight + winOffset.top], 15 )
        bottom: new Area( [winOffset.left, targetOffset.top + targetHeight], [winWidth + winOffset.left, winHeight + winOffset.top], 15 )
        left: new Area( [winOffset.left, winOffset.top], [targetOffset.left, winHeight + winOffset.top], 15 )

      
      # Pick best suitable area
      if /^(top|bottom)$/.test @options.position.at
        _flipPosition.call @ if popHeight > collisionsArea[@options.position.at].height() and collisionsArea[_getOppositePosition.call @].height() > collisionsArea[@options.position.at].height()
      else if /^(left|right)$/.test @options.position.at
        _flipPosition.call @ if popWidth > collisionsArea[@options.position.at].width() and collisionsArea[_getOppositePosition.call @].width() > collisionsArea[@options.position.at].width()
      
      suitableArea = collisionsArea[@options.position.at]



      if @options.position.at is 'top'
        if  @options.position.my is 'left'
          p1 = [targetOffset.left - 20 + targetWidth/2, targetOffset.top - popHeight - 15]
        else if  @options.position.my is 'right'
          p1 = [targetOffset.left + 20 - popWidth + targetWidth/2, targetOffset.top - popHeight - 15]
        else 
          p1 = [targetOffset.left + (targetWidth - popWidth)/2, targetOffset.top - popHeight - 15]
          
      else if @options.position.at is 'right'
        if  @options.position.my is 'top'
          p1 = [targetOffset.left + targetWidth + 15, targetOffset.top - 20 + targetHeight/2]
        else if  @options.position.my is 'bottom'
          p1 = [targetOffset.left + targetWidth + 15, targetOffset.top + 20 - popHeight + targetHeight/2]
        else 
          p1 = [targetOffset.left + targetWidth + 15, targetOffset.top + (targetHeight - popHeight)/2]

      else if @options.position.at is 'bottom'
        if  @options.position.my is 'left'
          p1 = [targetOffset.left - 20 + targetWidth/2, targetOffset.top + targetHeight + 15]
        else if  @options.position.my is 'right'
          p1 = [targetOffset.left + 20 - popWidth + targetWidth/2, targetOffset.top + targetHeight + 15]
        else 
          p1 = [targetOffset.left + (targetWidth - popWidth)/2, targetOffset.top + targetHeight + 15]
        
      else if @options.position.at is 'left'
        if  @options.position.my is 'top'
          p1 = [targetOffset.left - popWidth - 15, targetOffset.top - 20 + targetHeight/2]
        else if  @options.position.my is 'bottom'
          p1 = [targetOffset.left - popWidth - 15, targetOffset.top + 20 - popHeight + targetHeight/2]
        else 
          p1 = [targetOffset.left - popWidth - 15, targetOffset.top + (targetHeight - popHeight)/2]
        
            
      popArea = new Area( p1, [p1[0] + popWidth, p1[1] + popHeight])


      # Detect collisions
      collisions = suitableArea.detectCollisions popArea

      # Resolve collisions
      _resolveCollisions(collisions, suitableArea, popArea)
        
      # Anchor popup arrow to target
      if /^(top|bottom)$/.test @options.position.at
        arrowOffset = left: targetOffset.left + targetWidth/2 - popArea.offset().left
      else if /^(left|right)$/.test @options.position.at
        arrowOffset = top: targetOffset.top + targetHeight/2 - popArea.offset().top
      
      @html.$arrow.css arrowOffset

      # Align popup to area
      _appendPopupToArea.call @, popArea

      


    else if @type is 'modal'      
      collisionsArea = new Area( [winOffset.left, winOffset.top], [winWidth + winOffset.left, winHeight + winOffset.top], 50 )

      p1 = [(winWidth - popWidth)/2 + winOffset.left, (winHeight - popHeight)/2 + winOffset.top]
      popArea = new Area( p1, [p1[0] + popWidth, p1[1] + popHeight] )

      # Detect collisions
      collisions = collisionsArea.detectCollisions popArea

      # Resolve collisions
      _resolveCollisions(collisions, collisionsArea, popArea)
            
      # Align popup to area
      _appendPopupToArea.call @, popArea
        
  
  update: (data) ->
    self = @

    _setContent = (json) ->
      self.hide()
      self.trigger 'beforeRender', json
      $.extend self.data, json      
      self.html.$content.html( self.template.render(self.data) )            
      self.show()
      self.trigger 'afterRender'

    if typeof data is 'string'
      @html.$wrapper.addClass('uni-popup-loading')
      @reposition()
      $.ajax data,
        dataType: 'json'
        error: () ->
          $.uniPopup.open('error_500', { target: self.target })
        success: (json) ->                    
          self.html.$wrapper.removeClass('uni-popup-loading')
          _setContent(json)
          
          
    else if typeof data is 'object'      
      _setContent(data)
    
  $ -> do _init
   
    

class Popup extends Dialog  
  constructor: -> super


class Modal extends Dialog  
  constructor: -> super
  show: ->
    super        
    if window.hasOwnProperty('ontouchstart')
      _$overlay.css
        position: 'absolute'
        height: $(document).height()
        width: $(document).width()
    else
      _$overlay.removeAttr('style')

    _$overlay.show()


class Notification extends Dialog  
  constructor: -> super


$.uniDialog = 
  defaults: DEFAULTS

  register: (name, blueprint) ->              
    blueprint.events = blueprint.events || {}
    blueprint.callbacks = blueprint.callbacks || {}
    blueprint.i18n = blueprint.i18n || {}
    if window.HoganTemplates and window.Hogan and (window.HoganTemplates[blueprint.template] instanceof Hogan.constructor)    
      blueprint.template = HoganTemplates[blueprint.template]
    else if window.Hogan
      blueprint.template = Hogan.compile(blueprint.template)
    else
      blueprint.template = blueprint.template || ''
    TEMPLATES[name] = blueprint
        
  open: (name, options) ->
    options = options || {}
    type = options.type || DEFAULTS.DIALOG.type
    delete options.type
    data = options.data || {}
    delete options.data

    dialogTypes =       
      popup: Popup
      modal: Modal
      notification: Notification

    popup = new dialogTypes[type](name, type, data, options)
    popup.update data
    
    return popup

  closeAll: ->        
    #$.each OPENED["POPUPS"], (index, popup) -> popup.close()
    #$.each OPENED["MODALS"], (index, popup) -> popup.close()    