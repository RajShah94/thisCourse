define ["cs!base/views", "cs!./models", "hb!./templates.handlebars", "less!./styles", "cs!../userstatus/views"], \
        (baseviews, models, templates, styles, userstatusviews) ->

    class AdminRouterView extends baseviews.RouterView

        routes: =>
            # "/test": => view: TestView, datasource: "model"
            "": => view: AdminView
            # "/glossary": => view: glossaryviews.GlossaryListView, datasource: "course", key: "glossary"


    class AdminView extends baseviews.BaseView

        render: =>
            @$el.html templates.admin @context()
            @add_subview "#userstatuslist", new userstatusviews.UserStatusListView(), ".statuslist"
            
    
    class TestView extends baseviews.BaseView
        
        render: =>
            @$el.html templates.test @context()


    AdminRouterView: AdminRouterView
    AdminView: AdminView
    TestView: TestView