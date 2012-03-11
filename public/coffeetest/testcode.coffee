class window.BaseView extends Backbone.View

    constructor: (options) ->
        @subviews = {}
        visible = true
        @url = options.url if options?.url
        super
        @bind_links()
    
    bind_links: ->
        @$el.on "click", "a", (ev) ->
            if ev.shiftKey or ev.ctrlKey then return true
            if ev.target.origin != document.location.origin
                ev.target.target = "_blank"
                return true
            navigate ev.target.pathname
            return false

    show: =>
        if not @visible
            @visible = true
            @$el.show()

    hide: =>
        if @visible
            @visible = false
            @$el.hide()
            
    navigate: (fragment) =>
        #console.log "further navigating down into: '" + fragment + "'"
        @fragment = fragment
        for name, subview of @subviews
            return true if subview.navigate(@fragment)
        return false

    add_subview: (name, view, element) =>
        # close any pre-existing view at this name/slug
        @subviews[name].close?() if name of @subviews
        # create a back-reference to the parent view:
        view.parent = @
        # if the subview doesn't have a url, just use the current view's url:
        view.url or= @url
        # store it in the cache, by name/slug:
        @subviews[name] = view
        # now that we've added a new subview, re-navigate to check if the subview matches fragment:
        if @visible and @fragment # TODO: do we want to do this for non-visible views as well? Probably not?
            @navigate @fragment
        # append the view's element either to the specified target element, or to parent's top-level element
        $(element or @$el).append view.el
        return view
        

class window.RouterView extends BaseView
    
    _routeToRegExp: Backbone.Router.prototype._routeToRegExp

    initialize: =>
        @handlers = []
        @subviews = {}
        @route(route, callback) for route, callback of @routes
        super  

    route: (route, callback) =>
        # if the callback is a string, look it up as a method of this RouterView
        if _.isString(callback)
            callback = @[callback]
        # if the route isn't a RegExp, turn it into one
        if not _.isRegExp(route)
            route = @_routeToRegExp(route)
        # modify the regex so it will match urls that include trailing splats
        route = new RegExp("(" + route.source.replace("$", "") + ")(.*)$", "i")
        @handlers.unshift
            route: route
            callback: (fragment) ->
                callback route.exec(fragment).slice(2,-1)...
            get_match: (fragment) ->
                route.exec(fragment)[1]
            get_splat: (fragment) ->
                route.exec(fragment).slice(-1)[0]
    
    navigate: (fragment) =>
                
        console.log "navigating to", fragment, "in", @
        # check if fragment matches any of our routes
        for handler in @handlers

            if handler.route.test(fragment)
                
                # get the portion of the fragment that matched this pattern:
                match = handler.get_match(fragment)

                # get the cached view for this matching fragment (if it exists):
                subview = @subviews[match]

                # store the residual splat in the view for later propagation:
                splat = handler.get_splat(fragment)

                @fragment = match + splat

                # if we haven't already created a subview for this fragment, then make it so:
                if not subview
                    subview = handler.callback(fragment) # call the handler to get the new View instance
                    subview.url = @url + match
                    subview.render()
                    @add_subview match, subview
                
                # propagate the url fragment down into the subview:
                subview.navigate splat
                
                # make sure it's visible (hiding all others):
                view.hide() for route,view of @subviews when not (view is subview)
                subview.show()

                return true
            

class LectureRouterView extends RouterView

    className: "LectureRouterView"

    render: =>
        #@$el.text("This is the default.")

    routes:
        "": "create_lecture_list_view"
        ":lecture_id/": "create_lecture_view"

    create_lecture_list_view: =>
        console.log "create_lecture_list_view"
        return new LectureListView
            #collection: @collection

    create_lecture_view: (lecture_id) =>
        console.log "create_lecture_view " + lecture_id
        return new LectureView
            id: lecture_id
            #model: @collection.get(lecture_id)

class LectureListView extends BaseView

    className: "LectureListView"
    
    render: =>
        html = "<ul>"
        for num in [3,66,75,139]
            html += "<li><a href='" + @url + num + "'>Lecture " + num + "</a></li>"
        html += "</ul>"
        @$el.html html


class LectureView extends BaseView

    className: "LectureView"
    
    render: =>
        console.log "rendering lecture view:", @options.id
        @$el.text "Loading lecture..."
        setTimeout @actually_render, 500

    actually_render: =>
        @$el.text "This is lecture #" + @options.id
        @add_subview "pageview", new PageRouterView

class PageRouterView extends RouterView

    className: "PageRouterView"
    
    routes:
        "page/:id/": "create_content_view"
    
    create_content_view: (content_id) =>
        console.log "creating content view!!!"
        new ContentView
            id: content_id

class ContentView extends BaseView

    className: "ContentView"
    
    render: =>
        console.log "rendering page view:", @options.id
        @$el.text "Loading subpage..."
        setTimeout @actually_render, 500

    actually_render: =>
        @$el.text "This is subpage #" + @options.id
        
class HomeView extends BaseView

    render: =>
        @$el.html "<a href='/coffeetest/lecture/'>Lecture list</a>"


class window.CourseView extends RouterView

    className: "CourseView"
    
    routes:
        "": -> new HomeView
        "lecture/": -> new LectureRouterView

class RootView extends BaseView

    className: "RootView"

    el: $("body")

    render: =>
        @$el.html "<div class='tabs'></div><div class='contents'></div>"
        @add_subview "courseview", new CourseView, @$(".contents")


class BaseRouter extends Backbone.Router
    
    initialize: (options) =>
        @subviews = {}
        @rootview = new RootView(url: "/" + options.root_url)
        @rootview.render()
        @route options.root_url + "*splat", "delegate_navigation", (splat) =>
            if splat.length > 0 and splat.slice(-1) != "/"
                navigate options.root_url + splat
            else
                @rootview.navigate splat

window.router = new BaseRouter({root_url: "coffeetest/"})

window.navigate = (url) ->
    console.log "nav to", url
    if url.slice(-1) != "/"
        url += "/"    
    router.navigate(url, true)

Backbone.history.start({pushState: true})

