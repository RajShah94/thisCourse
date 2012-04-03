Backbone.Model.prototype.idAttribute = "_id"

class window.File extends Backbone.Model
    defaults:
        name:"file"
        fileurl: "picture.jpg"
        type: "picture"


class window.FileCollection extends Backbone.Collection
    model: File
    url: "/api/file/?_course=" + course_id


class window.FileView extends BaseView

    className: 'FileView'

    template = Handlebars.compile($('#fileview-template').html())

    events:
        'click .trash': 'clear'
        'click .file': 'select'
        'dblclick .file': 'selectChoose'

    initialize:=>
        @model?.bind 'change', @render
        @model?.bind 'destroy', @close

    render:=>
        @$el.append(template(@model.toJSON()))

    clear:=>
        @model.destroy()

    select:->
        @options.parent.$('.file').not(@$('.file')).removeClass('active')
        @$('.file').toggleClass('active')
        @options.parent.selected = @model

    selectChoose: =>
        @select()
        @options.parent.chooseFile()

    editName:->
        @$el.find('.file').find('.display,.edit').addClass('editing')

window.files = new FileCollection
files.fetch()

class window.BrowseView extends BaseView

    className: 'BrowseView'

    el: $("#filebrowser")

    template = Handlebars.compile($('#browseview-template').html())

    events:
        'change iframe#uploader': 'render'
        'click .nav .selectors': 'filterTypes'
        'click .nav .tagselectors': 'filterTags'
        'click button#select': 'chooseFile'

    initialize: =>
        @funcNum = @getUrlParam('CKEditorFuncNum')
        @courseid = @getUrlParam('courseid')
        @typefilter = @getUrlParam('typefilter')
        @typefilter?= 'all'
        @filteredcollection = @collection.filter (file) ->
            file.get('type') == @typefilter
        @tagfilter = null
        @collection.bind 'add', @render
        @render()
        @collection.fetch()

    getUrlParam: (paramName) ->
        reParam = new RegExp('(?:[\?&]|&amp;)' + paramName + '=([^&]+)', 'i')
        match = window.location.search.match(reParam)
        if match and match.length > 1 then match[1] else null

    render: =>
        @$el.html template()

        @$('#'+@typefilter).parent().addClass('active')
        @filteredcollection = @collection.filter (file) =>
            if @typefilter=='all'
                if @tagfilter? then @tagfilter in file.get('tags') else true
            else
                file.get('type') == @typefilter
        
        taglist = []

        for file in @filteredcollection
            for tag in (file.get('tags') or [])
                taglist.push(tag)
            fileView = new FileView
                model: file
                parent: @
            @$('.filelist').append(fileView.render())
        if taglist.length<1
            @$('.taglist').append("<li>No Tags</li>")
        else
            for tag in _.uniq(taglist)
                @$('.taglist').append("<li><a class='tagselectors' id='"+tag+"'>"+tag+"</a></li>")
        console.log @$('iframe.uploader')
        @$("iframe.uploader").load =>
            response_text = $("body", $("iframe").contents()).text()
            response_json = if response_text then JSON.parse(response_text) else {}
            if response_json.md5
                @loadDownloadFrame("Success!")
                @uploadFile(response_json)
            else if response_json._error
                @loadDownloadFrame("Error!")
        @loadDownloadFrame()

    uploadFile: (upload) =>
        file = new File upload
        @collection.add(file)

    chooseFile: ->
        window.opener.CKEDITOR.tools.callFunction(@funcNum, "/s3/file_redirect?id=" + @selected.id)
        self.close()

    filterTypes: (ev) =>
        @typefilter = ev.target.id
        @tagfilter = null
        @render()

    filterTags: (ev) =>
        @tagfilter = ev.target.id
        @typefilter = 'all'
        @render()

    loadDownloadFrame: (message) =>
            $.get("/s3?" + Math.random(), (policy_params) ->
                url = "https://thiscourse.s3.amazonaws.com/uploader/imageupload.html?" + Math.random() + "#policy:" + policy_params.policy + ",signature:" + policy_params.signature
                if message then url += ",message:" + message
                self.$("iframe.uploader").attr("src", url))
        
window.filebrowse = new BrowseView
    collection: files