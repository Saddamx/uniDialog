$.uniDialog.register 'notification',
  template: '<div class="jumbotron">
    <h1>Hello, world!</h1>
    <p>This is a template for a simple marketing or informational website. It includes a large callout called a jumbotron and three supporting pieces of content. Use it as a starting point to create something more unique.</p>
    <p>
      <a class="btn btn-primary btn-lg" href="#" role="button">Learn more »</a>
    </p>
    </div>'



$.uniDialog.register 'confirm-dialog',
  template: "templates/confirm_dialog"  
  i18n:
    pl:       
      cancel: 'anuluj'
      default_title: 'Usuń zasób'
      default_message: 'Usunięcie tego zasobu jest nieodwracalne. Czy chcesz kontynuować?'
      default_confirm_btn: 'usuń'
    en:       
      cancel: 'cancel'
      default_title: 'Delete resource'
      default_message: 'Deleting this resource is irreversible. Do you want to proceed?'
      default_confirm_btn: 'delete'
  events:
    'click .confirm-trigger': ->
      @close()
      href = @data.referrer.attr('href')      
      @data.referrer.trigger('click', true)
      if /\..+$/.test(href)        
        form = $('<form/>').attr('method', 'get').attr('action', href).hide().appendTo('body').submit()
        do form.remove
        
  callbacks:
    beforeRender: (json) ->
      json.confirm_btn = json.confirm_btn ? @data.i18n.default_confirm_btn
      json.title = json.title ? @data.i18n.default_title
      json.message = json.message ? @data.i18n.default_message


$.uniDialog.register 'alert-dialog',
  template: "templates/alert_dialog"   
  callbacks:
    beforeRender: (json) ->
      messages = []
      $.each json, (key, value) -> messages.push ({ message: value }) if /message/.exec(key)      
      json.messages = messages    